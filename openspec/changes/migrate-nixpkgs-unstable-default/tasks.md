## 1. Flake baseline migration

- [ ] 1.1 Update `flake.nix` so primary `inputs.nixpkgs` points to `github:NixOS/nixpkgs/nixos-unstable`.
- [ ] 1.2 Remove `inputs.nixpkgs-unstable` from `flake.nix` and remove related output arguments/usages.
- [ ] 1.3 Update dev-shell package selection to use the primary package set (remove `pkgsUnstable` usage).

## 2. Active module package-source cleanup

- [ ] 2.1 Update `modules/services/beets-inbox.nix` to stop importing `inputs.nixpkgs-unstable` and consume the primary package set instead.
- [ ] 2.2 Confirm no active code references remain to `nixpkgs-unstable` or `pkgsUnstable`.

## 3. Canonical documentation alignment

- [ ] 3.1 Update `docs/architecture.md` to state unstable-default package baseline policy.
- [ ] 3.2 Update `docs/decisions.md` with an explicit decision entry reflecting unstable-default and exception-only fallback behavior.
- [ ] 3.3 Update `docs/plan.md` so canonical planning language no longer assumes stable-first package baseline.
- [ ] 3.4 Update derived guidance (`CLAUDE.md`) where needed so it does not conflict with canonical docs.

## 4. Validation

- [ ] 4.1 Run `nix flake check --no-build` and resolve any evaluation issues from input rewiring.
- [ ] 4.2 Build `nixosConfigurations.oci-melb-1` and `nixosConfigurations.do-admin-1` to verify mixed-architecture host outputs still evaluate/build under unstable-default.
- [ ] 4.3 Verify host `system.stateVersion` values remain unchanged.
