## Why

Vaultwarden on `do-admin-1` needs a production-ready mail configuration for invites, verification, and admin workflows, and the current repo also needs a declarative way to publish the DNS records required by Resend for the `send.shrublab.xyz` sending domain. Capturing this work in OpenSpec aligns the already-started implementation with the repository's canonical planning and change-tracking workflow.

## What Changes

- Keep Cloudflare trusted proxy CIDRs as a single source of truth for edge reverse-proxy trust handling, while deferring host-firewall source restriction until origin reachability issues are resolved.
- Expand Vaultwarden service configuration to a production-oriented baseline, including domain/proxy settings, invite-only access, SMTP delivery, push support, security tuning, and host-scoped secret templating.
- Switch Vaultwarden SMTP delivery from Gmail-oriented settings to Resend SMTP using a dedicated sending subdomain.
- Add Cloudflare OpenTofu support for Resend DNS records for `send.shrublab.xyz`, including provider-variable inputs for DKIM/SPF/MX/optional DMARC values.
- Keep sensitive SMTP/API secrets host-scoped or OpenTofu-secret-scoped, while leaving public DNS verification material in non-secret config.

## Capabilities

### New Capabilities
- `vaultwarden-email-delivery`: Define declarative delivery and DNS requirements for Vaultwarden SMTP via Resend and the sending-domain DNS contract.

### Modified Capabilities
- `admin-services`: Add a declarative contract for Vaultwarden production mail/auth/runtime configuration.
- `edge-proxy-ingress`: Add a declarative contract for canonical trusted-proxy CIDR handling in edge reverse-proxy trust behavior.
- `secrets-management`: Clarify secret scoping for Vaultwarden SMTP/push secrets and OpenTofu mail-provider runtime secrets.

## Impact

- Affected Nix modules: `modules/services/admin/vaultwarden.nix`, `modules/services/edge-proxy-ingress.nix`, `modules/applications/edge-ingress.nix`
- Affected host config: `hosts/do-admin-1/default.nix`, `hosts/do-admin-1/secrets.nix`, `hosts/do-admin-1/secrets.template.yaml`
- Affected Cloudflare control-plane: `opentofu/cloudflare/{variables.tf,main.tf,config.auto.tfvars}`
- Affected systems: `do-admin-1` runtime behavior, Cloudflare DNS for `shrublab.xyz`, and host/OpenTofu secret handling
