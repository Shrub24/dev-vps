## Context

This change spans three connected areas that were already being implemented in the repo: tightening edge trusted-proxy handling for Cloudflare-fronted services, productionizing Vaultwarden mail/runtime configuration, and declaratively managing Resend DNS records for `send.shrublab.xyz` in the Cloudflare OpenTofu stack.

The repo already had a strong single source of truth for public web-service routing in `policy/web-services.nix` and a service-level single source of truth for Cloudflare trusted proxy CIDRs in `modules/services/edge-proxy-ingress.nix`. The missing pieces were:

- tighter reverse-proxy trust handling tied to the canonical Cloudflare CIDR source,
- Vaultwarden SMTP and secret templating beyond a minimal baseline,
- provider-oriented DNS variables that can express Resend-specific verification strings directly.

Stakeholders are the homelab operator and any future host/service additions that reuse the same admin and Cloudflare patterns.

## Goals / Non-Goals

**Goals:**
- Keep Cloudflare proxy CIDRs as the single value source for Caddy trusted proxy configuration.
- Make Vaultwarden usable as an invite-only production admin service with explicit SMTP, push, and security settings.
- Support Resend DNS verification declaratively in OpenTofu, with tfvars able to carry provider-specific record values directly where those values vary by provider or region.
- Preserve explicit blast-radius boundaries between public DNS data and secret SMTP/API credentials.

**Non-Goals:**
- Introduce a generic multi-provider mail abstraction beyond the variable surface needed now.
- Rework the canonical web-services routing policy model.
- Add new public-facing mail services outside the Resend sending-domain records required for Vaultwarden delivery.
- Guarantee OpenTofu apply/validate in environments that do not currently have `tofu` available.

## Decisions

### D1. Reuse `trustedProxyCidrs` for proxy trust behavior
The edge proxy module uses the existing Cloudflare CIDR list as the single value source for Caddy `trusted_proxies` rendering.

**Why:** This avoids duplicated CIDR literals and keeps edge trust behavior aligned across module layers.

**Alternative considered:** Duplicated trusted-proxy CIDR literals in Caddy/global config. Rejected because it creates drift risk and no operational benefit.

### D2. Defer host-firewall source restriction until origin reachability is better understood
Cloudflare continues to own DNS, Access, AOP, WAF, and related zone policy, while host firewall source restriction remains deferred after 522 troubleshooting showed the initial rollout needs more investigation.

**Why:** The repo still benefits from the trusted-proxy single source of truth, but the stricter firewall behavior should not be codified as the current baseline until origin reachability is proven.

**Alternative considered:** Keep the temporary firewall restriction as part of the archived baseline. Rejected because the code was intentionally rolled back and the archived change should match the current deployed direction.

### D3. Keep Vaultwarden non-secret behavior in Nix config and secrets in SOPS templates
Vaultwarden domain, SMTP host/port/security, feature flags, and security settings live in module config, while admin token, SMTP credentials, and push credentials are rendered through host-scoped SOPS templates.

**Why:** This matches existing repo secret patterns and keeps host-scoped credentials off the evaluated config surface.

**Alternative considered:** Put all SMTP settings in the env file. Rejected because non-secret values are better kept declarative and reviewable in Nix.

### D4. Use a dedicated sending subdomain for Resend
Vaultwarden sends mail from `send.shrublab.xyz` and uses Resend SMTP.

**Why:** A dedicated sending domain isolates mail-provider verification and aligns with provider recommendations for SPF/DKIM/MX/DMARC records.

**Alternative considered:** Send directly from root domain or Gmail SMTP. Rejected because it mixes unrelated mail concerns and leaves the repo with a less appropriate long-term provider setup.

### D5. Let tfvars carry provider-specific DNS strings directly where they vary
Cloudflare OpenTofu variables should accept provider/region-specific record names and values directly in tfvars for DKIM/SPF/MX/DMARC inputs, while only retaining simple defaults where the value is effectively standard.

**Why:** The operator is copying exact values from the Resend dashboard, and those values can vary by provider or region. Making tfvars closer to the provider UI reduces translation errors.

**Alternative considered:** Derive more record names and values from fixed templates. Rejected because it hides provider-specific details and makes mismatches harder to spot.

## Risks / Trade-offs

- **[Cloudflare CIDR drift]** Cloudflare source ranges can change. → **Mitigation:** keep the CIDR list centralized in `trustedProxyCidrs` so one update covers rendered reverse-proxy trust behavior.
- **[DNS naming confusion for subdomain mail records]** Provider dashboards often show FQDNs while Cloudflare inputs may use relative names. → **Mitigation:** prefer tfvars fields that mirror provider-visible strings directly where useful, and document the intended `send.shrublab.xyz` scope.
- **[Edge firewall hardening still unresolved]** Source-restricted host firewalling is still desirable defense in depth, but the first rollout caused origin reachability issues. → **Mitigation:** archive only the current trusted-proxy and Vaultwarden/Resend baseline, and revisit firewall restriction in a later focused change.
- **[Already-implemented work captured after the fact]** Some runtime/config changes landed before OpenSpec artifacts existed. → **Mitigation:** create a minimal retrospective change that documents final behavior and remaining follow-up tasks.

## Migration Plan

1. Capture the already-implemented trusted-proxy, Vaultwarden, and Resend wiring in OpenSpec artifacts.
2. Adjust Cloudflare tfvars so provider-specific Resend values can be pasted directly where appropriate.
3. Validate OpenSpec apply readiness and run strict validation.
4. Run Cloudflare formatting/validation/plan checks before apply.
5. Populate real Vaultwarden SMTP sender/secret values, deploy to `do-admin-1`, and confirm invite/email flow.

## Open Questions

- Should the OpenTofu variable model be normalized all the way to explicit `{ name, type, value, priority }` objects for every Resend record, or is a lighter direct-string adjustment sufficient?
- Should DMARC remain optional at `_dmarc.send` with `p=none` baseline, or should the repo adopt a stricter policy later after mail flow is proven?
