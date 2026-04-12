## 1. Ingress capability scaffolding

- [ ] 1.1 Add a modular Caddy ingress service module (or module set) that supports one primary domain, subdomain routes, and path-based routes.
- [ ] 1.2 Define a typed route schema with explicit exposure modes: `direct`, `tailscale-upstream`, `tailscale-only`.
- [ ] 1.3 Add host/application composition wiring so each host can declare independent route sets without service-local hardcoding.

## 2. Security and certificate integration

- [ ] 2.1 Add Cloudflare DNS-01 integration for Caddy certificates with host-scoped secret inputs (SOPS-backed).
- [ ] 2.2 Enforce private-by-default policy for admin/sensitive services (default access-gated edge + private-origin transport; `tailscale-only` as explicit mode).
- [ ] 2.3 Add guardrails that prevent undeclared public route exposure.

## 3. Host rollout and policy composition

- [ ] 3.1 Wire phase-1 host composition for edge/origin roles (e.g., edge host publishes selected routes, origin host remains private upstream).
- [ ] 3.2 Configure at least one service in each supported mode (`direct`, `tailscale-upstream`, `tailscale-only`) to validate modularity.
- [ ] 3.3 Ensure routing supports single-domain strategy with both subdomain and path routing per policy.

## 4. Verification and operator workflow

- [ ] 4.1 Add/extend contract tests for ingress route policy, exposure boundaries, and admin-route privacy defaults.
- [ ] 4.2 Add operational checks for Caddy health, certificate status, and route reachability.
- [ ] 4.3 Update docs/runbooks with phase-1 deploy/rollback instructions and explicitly deferred items (cache/failover).

## 5. Readiness checks

- [ ] 5.1 Run `openspec validate phase1-caddy-edge-proxy --strict` and resolve any issues.
- [ ] 5.2 Confirm change is apply-ready and hand off implementation command (`/opsx-apply`).
