## Context

`do-admin-1` recently lost in-band SSH during a remote networking ownership handoff, and recovery depended on provider console access plus manual rollback. The fleet already has private-first access, Kanidm-backed host auth, and host-scoped secrets, but it does not yet have a declared console break-glass user or a routine reboot exercise that proves remote hosts can come back cleanly.

This change targets both active hosts (`do-admin-1` and `oci-melb-1`) and must preserve the repo's existing operating model: Tailscale-first normal access, narrow host-scoped secrets, and simple host-centric module composition. Because the change adds security-sensitive access paths, the design must keep those paths explicit, host-scoped, and easy to disable or rotate.

## Goals / Non-Goals

**Goals:**
- Add a reusable host recovery baseline that can be enabled on active remote hosts.
- Provide a console break-glass path that is independent from the normal SSH and tailscale login path.
- Provide a host-scoped rescue user for password-based serial-console administration.
- Exercise host recoverability on a weekly cadence with a declared reboot timer.
- Keep recovery secrets and keys narrow, explicit, and auditable through host-scoped secret policy.
- Define operator workflows for rollout, verification, and rollback.

**Non-Goals:**
- Rework the normal Kanidm-backed host login model.
- Introduce public recovery ingress or weaken the Tailscale-first baseline for normal operations.
- Add initrd SSH, encrypted-root remote unlock, or a full disaster-recovery orchestration system in this change.
- Guarantee zero-downtime for risky networking changes; the goal is recoverability, not live cutover safety for every change.

## Decisions

### Decision 1: Model recovery as a dedicated shared host module with host-owned inputs

The recovery baseline should live in reusable shared/module wiring rather than ad hoc host-local fragments. Hosts should opt in explicitly and provide only host-owned values such as rescue password material and whether the rescue account is enabled.

**Rationale:** This matches the repo's thin-host/shared-module shape and avoids duplicating sensitive recovery logic across hosts.

**Alternatives considered:**
- Keep all recovery wiring host-local. Rejected because it duplicates sensitive logic and makes future hosts harder to onboard safely.
- Put recovery wiring directly into `modules/core/users.nix` only. Rejected because reboot exercise and host recovery policy are broader than user management.

### Decision 2: Defer initrd SSH and focus this change on console-only break-glass access

This change should stop at a console-only rescue path. Provider serial/console access already exists, and the immediate missing capability is a local password-authenticated rescue user when networking or SSH is unavailable. Initrd SSH remains useful, but it should be handled in a later change with provider-specific boot networking validation.

**Rationale:** This closes the actual operational gap now without guessing at host-specific initrd networking behavior.

**Alternatives considered:**
- Add initrd SSH immediately. Deferred because the host-specific boot networking assumptions are not yet validated and are not the current missing capability.
- Reuse the normal SSH users for console recovery. Rejected because the problem is specifically the absence of a password-authenticated console path when networking is broken.

### Decision 3: Keep the rescue user separate from Kanidm-backed human access

The rescue user should be an explicit local account intended only for break-glass use at the serial/provider console. It should be console-only, require a password, and use sudo with password. It must not silently become the default human admin path.

**Rationale:** Separation keeps normal identity flows intact and makes the rescue path easy to audit, rotate, or disable.

**Alternatives considered:**
- Extend the existing `dev` user for break-glass use. Rejected because it mixes routine and exceptional access.
- Use passwordless sudo for the rescue user. Rejected because the clarified requirement is an intentionally high-friction console-only break-glass path.

### Decision 4: Use an unconditional weekly reboot exercise

The weekly reboot should be implemented as a simple custom systemd timer/service rather than relying on update-triggered reboot helpers.

**Rationale:** The requirement is to exercise recoverability on a routine cadence even when no update is pending.

**Alternatives considered:**
- Use update-driven reboot features only. Rejected because those do not guarantee a weekly exercise.
- Omit scheduled reboots and rely on manual testing. Rejected because that lets recovery drift accumulate unnoticed.

### Decision 5: Keep recovery secrets under host-scoped SOPS policy

Recovery password hash material and any related rescue-only secret material should remain under host system/recovery secret scope with no implicit cross-host sharing.

**Rationale:** Recovery paths are high sensitivity and should follow the repo's existing narrow blast-radius model.

**Alternatives considered:**
- Store rescue password material in shared/common scope. Rejected because it broadens access for a sensitive capability.
- Manage recovery material outside the repo entirely. Rejected because the baseline needs a declarative audited contract, even if operators also retain out-of-band copies.

## Risks / Trade-offs

- **[Risk] Additional access surface increases security sensitivity** → Mitigation: keep recovery access host-scoped, console-only, and documented as break-glass only.
- **[Risk] Rescue password handling creates sensitive secret material** → Mitigation: store only password hashes in host-scoped SOPS secrets and document rotation expectations.
- **[Risk] Weekly reboots can interrupt workloads at bad times** → Mitigation: schedule a narrow maintenance window, keep cadence explicit, and verify services recover automatically afterward.
- **[Risk] Rescue account drifts into normal usage** → Mitigation: document purpose clearly, keep separate credentials, and avoid coupling it to routine workflows.
- **[Risk] Recovery rollout can itself cause lockout if misconfigured** → Mitigation: deploy with existing break-glass console access available, validate one host at a time if needed, and keep rollback commands in the operator runbook.

## Migration Plan

1. Add the shared recovery module and host-facing options.
2. Extend host secret policy and declare host-scoped rescue password material for `do-admin-1` and `oci-melb-1`.
3. Enable the recovery baseline on both active hosts with explicit host configuration.
4. Build and verify both host configurations locally.
5. Roll out using the existing safe remote workflow, keeping provider console access available.
6. Verify post-deploy recovery baseline: rescue user presence, console login path, weekly reboot timer, and normal service recovery.

Rollback strategy:
- Disable the host recovery module or host enablement flags and redeploy the previous generation.
- If remote access degrades, use provider console or the previous verified recovery path to boot a known-good generation.
- Rotate or remove rescue password material if rollout must be aborted after secret material has been staged.

## Open Questions

- Initrd SSH remains a useful follow-up change once provider-specific boot networking assumptions are confirmed.
