## Why

The admin module split left Termix in an inconsistent state: the real implementation still lives in a generic service module while `modules/services/admin/termix.nix` is only a thin wrapper. Cleaning this up now restores the intended admin ownership boundary and removes indirection without changing user-facing behavior.

## What Changes

- Move the canonical Termix module implementation into `modules/services/admin/termix.nix`.
- Eliminate the thin wrapper pattern between `services.admin.termix` and `services.termix`.
- Update admin composition and identity wiring to configure Termix through the admin-owned option namespace directly.
- Remove the obsolete generic `modules/services/termix.nix` import/path once the admin module owns the implementation.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `admin-module-structure`: clarify that admin-owned services should live directly under `modules/services/admin/` without redundant wrapper layers.
- `admin-services`: clarify that Termix is wired as a native admin service through `services.admin.termix` rather than via a generic service wrapper.

## Impact

- Affected code: `modules/services/admin/termix.nix`, `modules/services/termix.nix`, `modules/applications/admin/default.nix`, and `modules/applications/admin/identity.nix`.
- Affected systems: admin application composition and Termix OIDC/data-root wiring.
- No intended changes to service exposure, container runtime units, or host-facing Termix behavior.
