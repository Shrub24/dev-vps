## Why

The admin module split left behind a few thin wrapper layers and overly fragmented composition files that add indirection without adding meaningful ownership boundaries. This cleanup simplifies the admin module tree so admin-owned services live under canonical `services.admin.*` modules and portable admin composition lives in one reusable application module.

## What Changes

- Consolidate Pocket ID into the canonical admin service namespace under `modules/services/admin/pocket-id.nix`.
- Remove generic Pocket ID wrapper indirection and delete the obsolete generic composition module.
- Fold thin admin composition glue from `modules/applications/admin/access.nix` and `modules/applications/admin/identity.nix` into `modules/applications/admin/default.nix`.
- Flatten singleton Gatus module directory into a single service file (`modules/services/admin/gatus.nix`) to keep one-file-per-service consistency.
- Remove obsolete imports/files created only to forward or split small admin wiring fragments.

## Capabilities

### New Capabilities
- `admin-service-consolidation`: Define the simplified ownership model for admin-owned service modules and portable admin composition.

### Modified Capabilities
- `admin-module-structure`: Clarify that thin admin composition splits and generic passthrough wrappers are not the preferred canonical structure.
- `admin-services`: Clarify that Pocket ID and other admin auth composition are wired through canonical `services.admin.*` modules and portable `applications.admin` composition.

## Impact

- Affected code: `modules/applications/admin/default.nix`, `modules/applications/admin/access.nix`, `modules/applications/admin/identity.nix`, `modules/services/admin/pocket-id.nix`, `modules/services/pocket-id.nix`
- Affected systems: admin application composition, Pocket ID runtime wiring, Termix/Quantum OIDC composition, Tailscale-served Termix access
- No intended runtime behavior change beyond removing redundant layering and normalizing ownership boundaries
