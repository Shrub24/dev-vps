## Why

The repository currently uses a split package-set pattern (`nixos-25.11` as primary with targeted `nixos-unstable` imports) that adds maintenance overhead while still not meeting package freshness needs for active development. We should make `nixos-unstable` the default baseline now to simplify package sourcing and reduce exception-driven clutter in active code.

Core value: Keep fleet infrastructure practical and reproducible while reducing avoidable complexity in day-to-day host and module development.

## What Changes

- Switch primary flake input `nixpkgs` from `nixos-25.11` to `nixos-unstable`.
- Remove the dedicated `nixpkgs-unstable` flake input from active wiring.
- Update active code paths currently importing/using `nixpkgs-unstable` to use the primary package set.
- Update canonical documentation to reflect `unstable` as the default baseline (with exceptions allowed when concretely needed).
- Keep `system.stateVersion` unchanged on hosts; this change is package-set policy, not state-version migration.

## Capabilities

### New Capabilities
- `nixpkgs-baseline-policy`: Define and enforce a single default `nixos-unstable` package baseline for active fleet code.

### Modified Capabilities
- `fleet-infrastructure`: Update baseline package-source expectations and flake input policy from stable-first split usage to unstable-default.
- `repository-structure`: Update canonical documentation requirements so active docs reflect unstable-default package policy.

## Impact

- Affected code:
  - `flake.nix`
  - `modules/services/beets-inbox.nix`
- Affected documentation:
  - `docs/architecture.md`
  - `docs/decisions.md`
  - `docs/plan.md`
  - derived guidance in `CLAUDE.md` (if maintained in lockstep)
- Dependencies/systems:
  - Primary package source for both active hosts (`oci-melb-1`, `do-admin-1`) shifts to `nixos-unstable`
  - No Renovate/CI/CD automation changes in this change scope
