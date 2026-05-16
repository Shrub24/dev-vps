## Context

Beets import runners (`modules/services/beets/runners.nix`) use `set -euo pipefail`. When `beet import -q -C` exits non-zero (corrupted file, disk full, transient error), the script aborts immediately. This is correct behavior — demotion only fires on success, so unseen files stay in the inbox for re-attempt. But today there is no automatic re-attempt and no alert when this happens. The operator must notice the stalled inbox and manually re-trigger.

Two gaps:
1. **No recovery**: A transient failure leaves the inbox in limbo until manual intervention.
2. **No alert**: Silent failure — the operator doesn't know anything went wrong.

Both are solvable entirely at the systemd layer with zero runner code changes.

## Goals / Non-Goals

**Goals:**
- Automatically retry failed beets imports after a cooldown (10 minutes)
- Notify operator via ntfy.sh on failure with runner name + diagnostic context
- Cap retry loops at 3 attempts per 30 minutes to prevent thrashing
- Use only systemd primitives (OnFailure, timer units, template units) — no runner code changes
- Make ntfy notifications optional (graceful no-op if token not configured)

**Non-Goals:**
- Per-file failure tracking (demotion already handles skipped files)
- Differentiating failure causes (all non-zero exits trigger the same retry + alert)
- Retry for quarantine-interactive or reconcile runners (those are manual by design)
- Pre-flight file validation (ffprobe — defer until corruption is observed in practice)

## Decisions

### Decision 1: Retry via OnFailure timer, not inline loop

**Chosen:** Systemd timer unit triggered by `OnFailure=` on the runner service.

```
beets-inbox.service  →  OnFailure=beets-retry-inbox.timer
beets-retry-inbox.timer  →  10min cooldown  →  triggers beets-inbox.service again
```

**Rationale:** The import runner is a oneshot service. Retrying inline (loop inside the script) would consume the same systemd invocation and complicate logging. By using OnFailure → timer → re-trigger, each attempt gets its own systemd invocation, own journal entries, and own exit code. `StartLimitBurst=3` / `StartLimitIntervalSec=1800` (30min) on the runner service provides the loop cap for free.

**Alternative considered:** Inline retry loop in the runner script. Rejected because it would obscure per-attempt logging and make the runner script non-trivial.

### Decision 2: Retry timer cooldown is 10 minutes

**Chosen:** `OnActiveSec=10min` on the retry timer, triggered by `OnFailure=`.

**Rationale:** 10 minutes is long enough for transient issues (API rate limits, network blips) to resolve, but short enough that the operator doesn't wait long. Matches the user's explicit preference.

**Alternative considered:** 5 minutes. User preferred 10 for more breathing room on rate-limited APIs.

### Decision 3: Notification via systemd template unit, not runner code

**Chosen:** `beets-notify-failure@.service` template unit (OnFailure=, oneshot, curls ntfy.sh).

```
[Service]
Type=oneshot
ExecStart=${pkgs.curl}/bin/curl -H "Title: Beets %i failed" \
  -H "Priority: high" \
  -H "Tags: warning,beets" \
  -d "$(${pkgs.systemd}/bin/journalctl -u beets-%i.service -n 20 --no-pager)" \
  ${ntfyUrl}
```

Each generated runner service gets: `OnFailure=beets-notify-failure@%N.service`

**Rationale:** Systemd already knows when a unit fails. Adding notification to the runner scripts would duplicate that signal and add complexity. A template unit is ~15 lines, works for all runners universally, and can be extended per-runner via the `%i` instance parameter.

**Alternative considered:** Runner-script-level `trap ERR`. Rejected — tightly couples notification logic to runner implementation, harder to maintain across runner kinds.

### Decision 4: ntfy token via SOPS secret, optional

**Chosen:** `beets.notify.tokenFile` option pointing to a SOPS-decrypted file. If the file doesn't exist or the option is unset, the notify service is a no-op (curl without auth to a public topic, or skip entirely if `enable = false`).

```
beets.notify = {
  enable = true;
  ntfyUrl = "https://ntfy.sh/my-homelab-topic";
  tokenFile = config.sops.secrets."beets/ntfy_token".path;
};
```

**Rationale:** Avoids embedding tokens in the Nix store. Uses the existing SOPS pipeline (`sops-nix` decrypts at activation time). Graceful degradation if not configured.

### Decision 5: Retry only for import runner kind

**Chosen:** `beets/default.nix` conditionally generates retry timers only for runner instances where `runnerKind == "import"`.

**Rationale:** Quarantine-interactive and reconcile runners are manual-invocation by design. Retrying them automatically would be incorrect — the operator explicitly runs those, and a failure should wait for the operator, not auto-retry.

## Risks / Trade-offs

| Risk                                                               | Mitigation                                                                      |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| **Retry loop thrashing**: Corrupted file causes crash → retry → crash → ... | `StartLimitBurst=3` / `StartLimitIntervalSec=1800` caps at 3 failures per 30min   |
| **ntfy.sh unreachable**: curl fails, notify unit also exits non-zero      | Notify unit itself has no retry — one shot. Operator notices via silence or journal |
| **Token leakage in journal**: curl command with token shows in journalctl    | Use `--header "Authorization: Bearer $(cat $CREDENTIALS_DIRECTORY/ntfy_token)"` to keep token out of argv |
| **Retry timer persists across reboots**: timer stays active after reboot  | Deliberate — timer should fire. If the inbox is empty, import is a no-op.         |
| **Multiple runners fail simultaneously**: N ntfy alerts fire at once     | Acceptable — each alert names the specific runner. Not noisy enough to suppress.  |

## Open Questions

- Should the retry timer be manually stoppable by the operator? (Currently: `systemctl stop beets-retry-<runner>.timer` works, but the OnFailure wiring re-instantiates it on the next failure. Could add a `systemctl mask` workflow.)
- Should successful recovery after retry send a "resolved" ntfy notification? (Currently: only failure notifications. Adding success would double the notification volume for the common case.)
