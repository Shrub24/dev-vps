## Why

The repo currently enforces a private-first Tailscale baseline, but it lacks a modular reverse-proxy edge pattern for selectively exposing services by policy (public vs private). We need a phased approach that starts with low-complexity Caddy + Tailscale upstream routing and Cloudflare DNS-01 certificates, while deferring edge caching/failover until the base path is stable.

**Core Value**: Add a modular ingress layer that preserves security boundaries and enables per-service exposure modes without coupling hosts to one hardcoded network path.

## What Changes

- Add a Phase-1 modular Caddy reverse-proxy architecture for host/service ingress policy.
- Introduce per-service exposure modes:
  - `tailscale-upstream` for web services that should stay private-origin over Tailscale
  - `direct` for selected constant-availability services where Tailscale routing is operationally harmful
  - `tailscale-only` for services with no public web route
- Keep most services Tailscale-encrypted/reachable by default (`tailscale-upstream` or `tailscale-only`), and require explicit opt-in for `direct` public routing.
- Serve through a single primary domain with both subdomain routing and path-based routing support where appropriate.
- Add Cloudflare DNS challenge integration for Caddy certificate automation (DNS-01 only).
- Keep admin/sensitive services private-first by default; for web admin UIs, prefer Cloudflare Access at the edge with private-origin upstream.
- Define host-role composition so each host can independently serve selected services while sharing common module patterns.
- Defer Cloudflare edge cache rules and multi-origin failover/load-balancing to future phases.

## Capabilities

### New Capabilities
- `edge-proxy-ingress`: Modular Caddy ingress capability with per-service routing mode controls and host-scoped route composition.

### Modified Capabilities
- `network-access`: Add explicit hybrid ingress policy model (public edge host + private Tailscale upstream).
- `admin-services`: Add admin-route protection requirements under Caddy edge composition.
- `operations`: Add validation and smoke-check contracts for edge proxy health and route-policy correctness.
- `fleet-infrastructure`: Extend baseline architecture to include phased edge ingress while preserving low-complexity rollout discipline.

## Impact

- Affected modules: likely `modules/services/` and `modules/applications/` ingress/network composition and host defaults.
- Affected host configs: `hosts/oci-melb-1/default.nix`, `hosts/do-admin-1/default.nix` (service exposure composition).
- Affected operations/tests: phase contract tests and operator commands for ingress verification.
- Dependencies/systems: Caddy with Cloudflare DNS challenge plugin, Tailscale overlay for private upstreams, Cloudflare DNS records.
- Security posture impact: introduces controlled public ingress surface on designated edge host(s), requiring explicit guardrails and tests.
