## 1. Capture and align implemented behavior

- [x] 1.1 Restrict edge-host ports 80/443 to Cloudflare trusted proxy CIDRs using the same source of truth as proxy trust handling.
- [x] 1.2 Expand `modules/services/admin/vaultwarden.nix` to a production-oriented baseline with Resend SMTP, invite-only posture, push support, and security tuning.
- [x] 1.3 Render Vaultwarden host-scoped secrets through `hosts/do-admin-1/secrets.nix` and related host placeholders/templates.
- [x] 1.4 Add Cloudflare OpenTofu support for Resend sending-domain DNS records for `send.shrublab.xyz`.

## 2. Finish provider-facing configuration polish

- [x] 2.1 Update `opentofu/cloudflare/config.auto.tfvars` and any supporting variable surface so provider-specific Resend dashboard values can be pasted directly where appropriate.
- [x] 2.2 Re-check rendered naming for DKIM/SPF/MX/DMARC inputs against the `send.shrublab.xyz` sending-domain model after the tfvars adjustment.

## 3. Validate and close the change

- [x] 3.1 Validate Nix-side behavior with targeted evaluation for Vaultwarden SMTP and edge firewall rendering.
- [x] 3.2 Run `openspec validate --strict` and resolve any artifact issues.
- [x] 3.3 Run Cloudflare/OpenTofu formatting and validation when `tofu` tooling is available, or document the remaining external validation blocker.

## 4. Post-deploy fixups

- [x] 4.1 Fix Caddy trusted proxy rendering so Cloudflare CIDRs are emitted in valid `trusted_proxies static ...` syntax.
- [x] 4.2 Re-validate the rendered Caddy configuration and strict OpenSpec change state after the fix.

## 5. Temporary rollback

- [x] 5.1 Temporarily disable host firewall source restriction for edge ports 80/443 while investigating 522 origin reachability.
- [x] 5.2 Re-validate edge host firewall rendering and strict OpenSpec change state after the rollback.

## 6. Vaultwarden admin token fix

- [x] 6.1 Quote the rendered `ADMIN_TOKEN` env value so Argon2-hashed admin tokens are passed in the documented format.
- [x] 6.2 Re-validate strict OpenSpec change state after the Vaultwarden admin token template fix.
