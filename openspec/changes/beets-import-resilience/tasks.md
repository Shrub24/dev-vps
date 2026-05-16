## 1. Types — Notify config submodule

- [ ] 1.1 Add `beets.notify` submodule to `modules/services/beets/types.nix` with options: `enable`, `ntfyUrl`, `tokenFile`. Make `enable` default to `false` and all options optional.

## 2. Beets module — Retry timers + OnFailure wiring

- [ ] 2.1 In `modules/services/beets/default.nix`, generate retry timer units for each runner instance where `runnerKind == "import"`. Timer fires `OnActiveSec=10min` and targets the runner service. Use `wantedBy = [ runnerUnitName ]`.

- [ ] 2.2 Add `StartLimitBurst=3` and `StartLimitIntervalSec=1800` to all import runner service units (in the service unit definition, not the timer).

- [ ] 2.3 Wire `OnFailure=` on every generated runner service unit to both:
  - The retry timer unit (only for `import` runner kind)
  - `beets-notify-failure@<runner>.service` (for all runner kinds when notify is enabled)

## 3. Beets module — notify-failure template unit

- [ ] 3.1 Add `beets-notify-failure@.service` systemd template unit in `modules/services/beets/default.nix`. Oneshot, hardened (reuse `hardenedServiceDefaults`). `ExecStart` curls ntfy.sh with runner name in title and last 20 journal lines in body. Read auth token from `$CREDENTIALS_DIRECTORY` if configured; otherwise use unauthenticated topic.

- [ ] 3.2 Handle the no-token case: if `tokenFile` is null, send to ntfy without auth. If `ntfyUrl` is null, the notify template should not be generated or should be a no-op.

## 4. Music module — Notify config wiring

- [ ] 4.1 In `modules/applications/music.nix`, add `beets.notify` configuration block referencing a new SOPS secret for the ntfy token.

- [ ] 4.2 Add `beets.notify.tokenFile` pointing to `config.sops.secrets."beets/ntfy_token".path`.

## 5. Secrets

- [ ] 5.1 Add `beets.ntfy_token` SOPS secret definition in `modules/applications/music.nix` or `secrets/common.yaml`. Make optional (no `isRequired = true`).

- [ ] 5.2 Update `.sops.yaml` if needed to include the new secret in the appropriate scope.

## 6. Validation and deploy

- [ ] 6.1 Run `nix flake check --no-build` to validate evaluation.

- [ ] 6.2 Deploy to `oci-melb-1` via `just deploy oci-melb-1` and confirm all units are generated correctly with `systemctl list-units 'beets-*'`.

- [ ] 6.3 Smoke test: simulate a failure (e.g., trigger import against empty or bad target), verify ntfy notification fires, verify retry timer activates, verify StartLimitBurst caps retries after 3 failures.

- [ ] 6.4 Update `tasks.md` checkboxes to reflect completion.
