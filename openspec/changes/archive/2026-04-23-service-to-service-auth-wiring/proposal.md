## Why

Homepage and other admin caller flows currently lack a consistent, caller-owned machine-auth contract. This creates drift between route policy, app-level human auth, and internal service-to-service access. We need a clear baseline now to keep blast radius low as cross-host admin flows grow.

Core Value: establish a reproducible, low-complexity internal auth wiring model that is private-first, host-scoped, and practical for day-1 operations.

## What Changes

- Define a caller-owned machine-auth model, starting with Homepage integrations.
- Keep `policy/web-services.nix` focused on routing/access/health metadata; do not move integration credentials into policy routes.
- Standardize auth preference order per integration: local-only no-credential (explicit), native token/API key, app-specific machine account/client credential, username/password fallback.
- Wire Homepage secrets through host-scoped SOPS templates and `services.homepage-dashboard.environmentFiles`.
- Add Beszel Homepage integration using a dedicated read-only app account.
- Add Beszel agent machine-auth wiring using host-scoped credentials and per-host environment templates.
- Preserve current no-auth local Caddy widget exception and keep Filebrowser widget auth out of scope for this change.

## Capabilities

### New Capabilities
- `internal-service-auth`: Defines caller-owned internal service-to-service auth contracts, secret scoping, and integration-specific auth method selection.

### Modified Capabilities
- `admin-services`: Extend admin Homepage behavior to require explicit caller-owned machine-auth wiring for authenticated widgets while preserving presentation ownership in Homepage files.

## Impact

- Affected code paths:
  - `modules/services/admin/homepage/default.nix`
  - `modules/services/admin/homepage/data.nix`
  - `hosts/do-admin-1/secrets.nix`
  - `hosts/do-admin-1/secrets.template.yaml`
  - `hosts/oci-melb-1/default.nix`
  - `hosts/oci-melb-1/secrets.template.yaml`
- Affected specs:
  - New: `openspec/specs/internal-service-auth/spec.md`
  - Modified: `openspec/specs/admin-services/spec.md`
- Security impact:
  - More explicit host-scoped caller credentials
  - Reduced risk of shared cross-service credentials
- Operational impact:
  - Beszel requires one-time manual read-only account bootstrap and scoped sharing
