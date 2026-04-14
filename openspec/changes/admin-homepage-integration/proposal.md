## Why

Homepage is already enabled in the admin profile, but it is not yet the canonical operator landing page for admin services. We need a single, stable endpoint at `admin.shrublab.xyz` with practical widgets/links so day-to-day operations can start from one place while preserving private-origin and access-gated admin posture.

**Core Value:** deliver one reliable, low-friction admin dashboard entrypoint that improves operational visibility without widening default exposure risk.

## What Changes

- Add homepage service/widget/link wiring for existing admin services, prioritizing native homepage integrations where available.
- Add a dedicated edge-ingress route for Homepage at `admin.shrublab.xyz`.
- Keep admin ingress policy explicit and Cloudflare Access-gated, with private-origin upstream transport.
- Define a phased widget baseline that tolerates auth-protected backends during initial rollout (links always present; widgets enabled where practical).
- Add contract coverage for homepage route and visibility baseline behavior.

## Capabilities

### New Capabilities
- *(none)*

### Modified Capabilities
- `admin-services`: clarify Homepage as central admin dashboard surface with prioritized Cockpit/Beszel/Gatus visibility blocks and service links.
- `edge-proxy-ingress`: add explicit `admin.shrublab.xyz` homepage route behavior under Cloudflare Access-gated, private-origin defaults.

## Impact

- Affected code:
  - `modules/applications/admin.nix`
  - `modules/applications/edge-ingress.nix`
  - `modules/services/edge-proxy-ingress.nix`
  - `hosts/do-admin-1/default.nix`
  - `tests/phase-do-admin-contract.sh`
  - `tests/phase-05-edge-ingress-contract.sh`
- Affected systems:
  - `do-admin-1` (homepage route ownership and dashboard wiring)
- Dependencies:
  - Existing Cloudflare Access + edge-ingress policy model
  - Existing admin services already enabled in `applications.admin`
