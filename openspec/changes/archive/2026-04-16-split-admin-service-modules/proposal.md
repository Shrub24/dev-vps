## Why

The admin stack has grown quickly (OIDC, Cloudflare Access alignment, OpenTofu-era route policy), but `modules/applications/admin.nix` is now a large mixed-responsibility file and `hosts/do-admin-1/default.nix` carries too much host glue in one place. This reduces maintainability and makes future host expansion riskier.

**Core Value:** preserve the current private-first admin behavior while making admin service composition modular, policy-driven, and easier to evolve safely.

## What Changes

- Refactor admin wiring from one large `modules/applications/admin.nix` into a structured module tree.
- Introduce service-level admin modules under `modules/services/admin/` (with subdirectories for complex services).
- Keep `applications.admin` as the single composition entrypoint under `modules/applications/admin/default.nix`.
- Split complex service payloads into adjacent data files (especially Homepage and Gatus support files).
- Derive Gatus endpoint inventory from `policy/web-services.nix` via existing policy resolution helpers.
- Consolidate SSOT for routed service metadata so domain, subdomain, route path, and origin port are defined once and consumed everywhere else.
- Keep Homepage presentation metadata separate from policy (no Homepage derivation from route policy).
- Keep Cockpit in migrated admin module structure but set `enabled = false` as a documented temporary host-level exception due upstream regression.
- Perform a light `hosts/do-admin-1` split into `secrets.nix`, `edge.nix`, and `networking.nix` while preserving behavior.
- Preserve existing private/Tailscale-first posture and existing service ownership by admin composition.
- Keep this as a structural refactor (no admin subgroup toggles in this change).

## Capabilities

### New Capabilities
- `admin-module-structure`: Define the canonical layered structure for admin service modules, admin application composition, and host-local admin assembly.

### Modified Capabilities
- `admin-services`: Update requirements to reflect modular admin service ownership, policy-derived Gatus inventory, and split host composition while preserving current behavior.
- `edge-proxy-ingress`: Update ingress requirements so the primary domain and routed subdomains/paths are consumed from canonical policy configuration instead of duplicated literals.
- `repository-structure`: Update repository structure expectations for admin module/layout organization and host file decomposition.

## Impact

- Affected code:
  - `modules/applications/admin.nix` (replaced by `modules/applications/admin/default.nix` and related composition files)
  - `modules/services/admin/**` (new service-level modules)
  - `hosts/do-admin-1/default.nix` plus new host split files (`secrets.nix`, `edge.nix`, `networking.nix`)
  - policy-consumption wiring for Gatus endpoint generation using `policy/web-services.nix` and `lib/policy.nix`
  - canonical domain/service routing metadata consumption for edge and service modules
- Affected systems:
  - `do-admin-1` admin service composition and edge-policy consumption
- Constraints honored:
  - no new public-ingress defaults
  - host-scoped secret posture preserved
  - private-origin + Tailscale-first operational model preserved
  - sequence after `migrate-nixpkgs-unstable-default` to avoid transitional package-source churn in new module files
