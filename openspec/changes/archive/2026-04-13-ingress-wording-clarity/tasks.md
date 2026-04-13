## 1. OpenSpec wording deltas

- [x] 1.1 Add `operations` delta for ingress wording clarity
- [x] 1.2 Confirm all modified delta requirement headers exactly match state spec headers

## 2. Architecture and decisions wording alignment

- [x] 2.1 Update `docs/architecture.md` to explicitly describe public edge bastion (Cloudflare + Caddy)
- [x] 2.2 Update `docs/architecture.md` to clarify `tailscale-upstream` (cross-host), `direct` (edge-local localhost), and `tailscale-only`
- [x] 2.3 Update `docs/decisions.md` access/ingress decisions to match the same terminology

## 3. Validation

- [x] 3.1 Run `openspec validate ingress-wording-clarity --strict`
- [x] 3.2 Run `openspec validate --specs --strict`
