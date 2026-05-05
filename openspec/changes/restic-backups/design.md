## Context

The repository intentionally separates immutable repo-owned configuration from mutable runtime state, with service data concentrated under `/srv/data` and media payloads under `/srv/media`. Today there is no canonical fleet backup contract, even though both hosts run stateful services and at least three services require export-aware handling (`kanidm`, `vaultwarden`, and `tagr`).

This change is cross-cutting because it affects host modules, service modules, secret scoping, operator workflows, and recovery expectations across both `do-admin-1` and `oci-melb-1`. It also needs to fit the existing repository patterns: shared reusable modules, host-thin bindings, path-scoped SOPS rules, and Tailscale-first recoverability.

## Goals / Non-Goals

**Goals:**
- Define one canonical fleet backup architecture for mutable host state.
- Use NixOS-native `services.restic.backups` instead of introducing separate orchestration tooling.
- Keep credentials host-scoped with one dedicated backup bucket and one restic repository per host.
- Reuse shared non-secret S3 defaults from `policy/globals.nix`.
- Define service consistency classes so export-aware services can produce more recoverable backup artifacts.
- Keep initial rollout safe and incremental across both hosts while preserving a later path to broader service coverage.
- Establish explicit restore and validation expectations, not only recurring backup jobs.

**Non-Goals:**
- Back up `/srv/media` in this first change.
- Introduce snapshot orchestration, cross-host deduplicated shared repos, or non-restic backup tooling.
- Guarantee application-specific point-in-time transactional consistency for every service in the first wave.
- Finalize every service-specific export command now where current module internals still need deeper verification.
- Replace existing object-storage usage for applications such as Karakeep; backup storage remains a separate concern.

## Decisions

1. **Use NixOS `services.restic.backups` as the canonical execution surface**
   - Rationale: it is the most idiomatic and lowest-complexity fit for this repo, already supports timers, initialization, prune, checks, and hook commands, and keeps backup behavior declarative inside host configuration.
   - Alternative considered: bespoke systemd units or wrapper scripts around `restic`.
   - Why not chosen: they add moving parts and duplicate NixOS-native capability without clear benefit.

2. **Adopt one dedicated backup bucket and one restic repository per host**
   - Rationale: this gives the cleanest isolation model for long-lived static R2 credentials, aligns with host-scoped blast-radius boundaries, and avoids depending on temporary-credential prefix scoping machinery.
   - Alternative considered: one shared bucket with host-specific prefixes or one shared repo.
   - Why not chosen: shared-bucket prefix isolation is not strong with normal long-lived R2 credentials, while a shared repo would weaken host isolation too much.

3. **Reuse shared non-secret S3 defaults but keep backup credentials host-scoped**
   - Rationale: endpoint, region, and path-style behavior are already canonical in `policy/globals.nix`, while access key, secret key, and restic password belong in normal host secret scope.
   - Alternative considered: duplicate full S3 configuration under backup-specific config.
   - Why not chosen: would create drift between application object storage defaults and backup transport defaults with no security gain.

4. **Define three consistency classes: `export`, `quiesce`, and `live`**
   - `export`: service prepares an app-native restorable recovery artifact before backup; raw state may also be captured.
   - `quiesce`: service is briefly stopped or otherwise stabilized around the backup window.
   - `live`: service state is safe enough to capture without explicit coordination in the first wave.
   - Rationale: this gives a clean contract that can be shared across services while preserving service-specific implementation details.
   - Alternative considered: one uniform stop/start policy for all services.
   - Why not chosen: too disruptive, not always necessary, and poorly aligned with mixed service types.

5. **Use export + raw state for export-first services in the initial contract**
   - Rationale: user explicitly chose this posture. It balances app-native recovery artifacts with exact-state recovery and is especially valuable for Kanidm and SQLite-backed services during early rollout.
   - Alternative considered: export-only backups.
   - Why not chosen: lowers forensic and exact-state recovery flexibility while service contracts are still maturing.

6. **Keep backup scope explicit and state-focused in the first wave**
   - Include: mutable service state directories and generated export artifacts.
   - Exclude: repo-owned immutable config and `/srv/media`.
   - Rationale: this keeps the first backup architecture narrow, affordable, and aligned with the user’s current stated scope.
   - Alternative considered: backing up all mutable paths including media immediately.
   - Why not chosen: larger cost/surface area and less clarity about authoritative media ownership.

7. **Model backup ownership as a shared backup module plus service-owned backup metadata/contracts**
   - Rationale: preserves existing repository ownership patterns. Hosts should mostly bind enablement, bucket naming, and secret paths; service modules should declare their own backup-relevant paths and hooks where needed.
   - Alternative considered: put all backup path logic directly in host modules.
   - Why not chosen: would reintroduce host-level service ownership and make future host expansion harder.

8. **Treat restore validation as a first-class operator concern**
   - Rationale: recurring backups without restore expectations are insufficient. The operator contract should require repository initialization, backup checks, and at least documented restore verification for critical services.
   - Alternative considered: define backup creation only and defer restore workflow entirely.
   - Why not chosen: conflicts with the repo’s recoverability-first operational posture.

## Risks / Trade-offs

- **[Risk] Some services may appear filesystem-safe but need app-specific export or quiesce behavior** → Mitigation: define consistency class contracts now, start with clearly verified export-first services, and leave unresolved services as explicit follow-up items instead of guessing.
- **[Risk] Export + raw-state backups increase storage usage** → Mitigation: accept duplication initially for recovery safety, then revisit per-service slimming once restore confidence improves.
- **[Risk] Backup hooks can make systemd units or timers more brittle** → Mitigation: keep hook contracts narrow, prefer deterministic generated artifact paths, and validate failure behavior before broad rollout.
- **[Risk] Host-scoped credential management adds secret entries per host** → Mitigation: keep backup credentials in normal host secret files and reuse shared non-secret transport defaults to minimize duplication.
- **[Risk] Restore procedures may lag behind backup implementation** → Mitigation: make restore runbook work and validation tasks part of the same change rather than a later optional follow-up.

## Migration Plan

1. Add the new `state-backups` capability spec and related spec deltas for fleet, operations, secrets, admin, and media capabilities.
2. Introduce a shared backup module contract and wire thin host bindings for both hosts.
3. Add host-scoped backup secrets and repository/bucket configuration using existing S3 transport defaults.
4. Implement export-first handling for known critical services (`kanidm`, `vaultwarden`, `tagr`) and basic path coverage for other included service state, using Kanidm's upstream automatic backup artifact as its export-style payload.
5. Add operator-facing commands or documentation for init, backup, check, prune, and restore validation.
6. Validate with flake/build checks, OpenSpec validation, and targeted backup/restore sanity checks before marking rollout complete.

Rollback: disable the backup module per host and remove timers/hooks from host configuration while retaining untouched service runtime state. Because backup storage is append-oriented and host-isolated, rollback of configuration does not require destructive repository changes.

## Open Questions

- Which additional currently deployed services need `export` rather than `quiesce` or `live` after deeper module verification (`karakeep`, `ntfy`, `homepage`, `beszel`, etc.)?
- Should generated export artifacts live under a dedicated backup staging subtree inside `/srv/data`, `/var/lib`, or a transient runtime path before restic capture?
- What exact retention/check defaults should become the fleet baseline (for example daily cadence, prune windows, and regular `restic check` depth)?
- How much restore automation should be implemented in this change versus documented as manual runbook steps?
