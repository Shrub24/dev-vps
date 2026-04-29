## 1. Artifact and namespace consolidation

- [x] 1.1 Canonicalize Pocket ID under `modules/services/admin/pocket-id.nix` with `services.admin.pocket-id` options and runtime wiring
- [x] 1.2 Remove obsolete generic Pocket ID wrapper/module usage and update all references to the canonical admin namespace

## 2. Portable admin composition cleanup

- [x] 2.1 Merge `modules/applications/admin/access.nix` into `modules/applications/admin/default.nix`
- [x] 2.2 Merge `modules/applications/admin/identity.nix` into `modules/applications/admin/default.nix`
- [x] 2.3 Remove obsolete imports/files created only for the split glue structure

## 3. Validation

- [x] 3.1 Run targeted evaluation checks for Pocket ID, Termix access wiring, and OIDC composition
- [x] 3.2 Run `openspec validate "admin-module-consolidation-refactor" --strict`
