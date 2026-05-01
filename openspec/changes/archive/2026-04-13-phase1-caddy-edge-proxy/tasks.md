## 1. Ingress capability scaffolding

- [x] 1.1 Add a modular Caddy ingress service module (or module set) that supports one primary domain, subdomain routes, and path-based routes.
- [x] 1.2 Define a typed route schema with explicit exposure modes, with phase-1 defaulting to `tailscale-upstream`/`tailscale-only` and `direct` deferred to explicit edge-local exception use.
- [x] 1.3 Add host/application composition wiring so each host can declare independent route sets without service-local hardcoding.

## 2. Security and certificate integration

- [x] 2.1 Add Cloudflare DNS-01 integration for Caddy certificates with host-scoped secret inputs (SOPS-backed).
- [x] 2.2 Enforce private-by-default policy for admin/sensitive services (default access-gated edge + private-origin transport; `tailscale-only` as explicit mode).
- [x] 2.3 Add guardrails that prevent undeclared public route exposure.

## 3. Host rollout and policy composition

- [x] 3.1 Wire phase-1 host composition for edge/origin roles (e.g., edge host publishes selected routes, origin host remains private upstream).
- [x] 3.2 Validate modularity with `tailscale-upstream` and `tailscale-only` in phase-1; treat `direct` as deferred unless explicitly required for an edge-local exception.
- [x] 3.3 Ensure routing supports single-domain strategy with both subdomain and path routing per policy.

## 4. Verification and operator workflow

- [x] 4.1 Add/extend contract tests for ingress route policy, exposure boundaries, and admin-route privacy defaults.
- [x] 4.2 Add operational checks for Caddy health, certificate status, and route reachability.
- [x] 4.3 Update docs/runbooks with phase-1 deploy/rollback instructions and explicitly deferred items (cache/failover).

## 5. Readiness checks

- [x] 5.1 Run `openspec validate phase1-caddy-edge-proxy --strict` and resolve any issues.
- [x] 5.2 Confirm change is apply-ready and hand off implementation command (`/opsx-apply`).
