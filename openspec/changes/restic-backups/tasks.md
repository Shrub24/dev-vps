## 1. Establish backup architecture and shared module surface

- [x] 1.1 Add a shared backup module that wraps canonical `services.restic.backups` behavior, consumes shared non-secret S3 defaults, and exposes host-scoped options for repository, bucket, credentials, schedule, retention, and checks.
- [x] 1.2 Define explicit backup scope inputs and exclusions so mutable service state is sourced from managed state roots while `/srv/media` remains excluded in this wave.
- [x] 1.3 Add backup-mode contracts (`export`, `quiesce`, `live`) in repo-owned module/service interfaces so services can declare consistency requirements without shifting ownership into host modules.

## 2. Wire host-scoped repository and secret contracts

- [x] 2.1 Add host-scoped backup credential and restic password secret inputs for `do-admin-1` and `oci-melb-1` following existing host secret patterns and `.sops.yaml` blast-radius rules.
- [x] 2.2 Bind both active hosts to dedicated per-host backup buckets and repositories using thin host-level configuration only.
- [x] 2.3 Validate that host backup configuration reuses canonical non-secret S3 transport defaults from `policy/globals.nix` rather than duplicating endpoint policy.

## 3. Implement service backup behavior

- [x] 3.1 Implement export-first backup behavior for Kanidm using its upstream automatic backup artifact, with initial raw-state coverage.
- [x] 3.2 Implement export-first backup behavior for Vaultwarden and Tagr, including portable export generation and initial raw-state coverage.
- [x] 3.3 Classify and wire remaining in-scope stateful services across both hosts as `quiesce` or `live`, documenting any deferred unknowns that need a later follow-up change.

## 4. Add operator workflows and validation

- [x] 4.1 Add operator-facing documentation or command entrypoints for repository initialization, on-demand backup execution, prune/check flows, and restore preparation.
- [x] 4.2 Add restore-validation guidance or executable sanity checks for critical services so backup success is not the only acceptance signal.
- [ ] 4.3 Run repo validation (`nix fmt`, relevant builds/checks, and `openspec validate --strict`) and capture any service-specific backup caveats before implementation completion.
