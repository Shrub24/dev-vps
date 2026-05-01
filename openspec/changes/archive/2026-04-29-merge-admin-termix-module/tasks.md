## 1. OpenSpec and module alignment

- [x] 1.1 Consolidate the Termix implementation into `modules/services/admin/termix.nix` and remove the obsolete generic wrapper/module path.
- [x] 1.2 Update admin composition/identity wiring to configure Termix through `services.admin.termix` only.

## 2. Validation

- [x] 2.1 Run targeted repo validation for the Termix/admin refactor.
- [x] 2.2 Run `openspec validate --strict` and confirm the change is implementation-complete.
