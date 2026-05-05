## Why

The fleet currently has no canonical backup contract for mutable service state, even though critical runtime data is intentionally concentrated under `/srv/data` and several services rely on SQLite or application-managed identity state. We need a repo-native, host-scoped backup architecture now so both hosts can gain reliable incremental backups, clear recovery posture, and blast-radius-aligned secret handling before more state accumulates.

## What Changes

- Add a fleet backup architecture based on NixOS `services.restic.backups` and S3-compatible object storage, with one dedicated backup bucket and one host-scoped restic repository per host.
- Define canonical backup scope boundaries so repo-owned immutable config is excluded, service state under `/srv/data` is included, and `/srv/media` remains out of initial scope.
- Define service backup consistency classes (`export`, `quiesce`, `live`) and require export-first handling for Kanidm, Vaultwarden, and Tagr, where Kanidm's export artifact is its app-native automatic backup output, while still capturing raw state initially for recovery flexibility.
- Define host-scoped backup secret contracts that reuse shared non-secret S3 defaults from `policy/globals.nix` while keeping per-host access keys, secrets, and restic passwords in normal host secret scope.
- Add operator requirements for backup initialization, recurring execution, retention, integrity checks, and restore validation/runbooks.

## Capabilities

### New Capabilities
- `state-backups`: Defines the canonical fleet backup architecture, scope, repository layout, consistency classes, retention/check expectations, and restore posture for mutable host state.

### Modified Capabilities
- `fleet-infrastructure`: Add baseline requirements for host-scoped state backup coverage as part of recoverable fleet operations.
- `operations`: Add operator runbook and validation requirements for backup execution, restore testing, and recovery workflows.
- `secrets-management`: Add path-scoped host secret handling for per-host backup credentials and repository passwords.
- `admin-services`: Add backup/export behavior requirements for admin-stack stateful services such as Kanidm and Vaultwarden.
- `media-services`: Add backup/export behavior requirements for stateful music-stack services such as Tagr while keeping media payloads out of initial scope.

## Impact

- Affected code paths:
  - `modules/` backup-related shared module(s) and service modules with backup metadata/hooks
  - `hosts/do-admin-1/default.nix`
  - `hosts/oci-melb-1/default.nix`
  - `policy/globals.nix` consumption for shared non-secret S3 defaults
  - `secrets/hosts/<host>/system.yaml` or equivalent host-scoped secret templates/contracts
  - operational docs/runbooks under `docs/` and/or repo operator entrypoints
- Affected specs:
  - New: `openspec/specs/state-backups/spec.md`
  - Modified: `openspec/specs/fleet-infrastructure/spec.md`
  - Modified: `openspec/specs/operations/spec.md`
  - Modified: `openspec/specs/secrets-management/spec.md`
  - Modified: `openspec/specs/admin-services/spec.md`
  - Modified: `openspec/specs/media-services/spec.md`
- Operational impact:
  - Both hosts gain a common backup architecture with host-isolated credentials and storage.
  - Recovery posture becomes explicit for identity/admin and SQLite-backed services.
  - Backup rollout introduces recurring jobs, retention policy, and restore-verification expectations.
