## 1. Flake baseline migration

- [x] 1.1 Update `flake.nix` so primary `inputs.nixpkgs` points to `github:NixOS/nixpkgs/nixos-unstable`.
- [x] 1.2 Remove `inputs.nixpkgs-unstable` from `flake.nix` and remove related output arguments/usages.
- [x] 1.3 Update dev-shell package selection to use the primary package set (remove `pkgsUnstable` usage).

## 2. Active module package-source cleanup

- [x] 2.1 Update `modules/services/beets-inbox.nix` to stop importing `inputs.nixpkgs-unstable` and consume the primary package set instead.
- [x] 2.2 Confirm no active code references remain to `nixpkgs-unstable` or `pkgsUnstable`.

## 3. Canonical documentation alignment

- [x] 3.1 Update `docs/architecture.md` to state unstable-default package baseline policy.
- [x] 3.2 Update `docs/decisions.md` with an explicit decision entry reflecting unstable-default and exception-only fallback behavior.
- [x] 3.3 Update `docs/plan.md` so canonical planning language no longer assumes stable-first package baseline.
- [x] 3.4 Update derived guidance (`CLAUDE.md`) where needed so it does not conflict with canonical docs.

## 4. Validation

- [x] 4.1 Run `nix flake check --no-build` and resolve any evaluation issues from input rewiring.
- [x] 4.2 Build `nixosConfigurations.oci-melb-1` and `nixosConfigurations.do-admin-1` to verify mixed-architecture host outputs still evaluate/build under unstable-default.
- [x] 4.3 Verify host `system.stateVersion` values remain unchanged.
