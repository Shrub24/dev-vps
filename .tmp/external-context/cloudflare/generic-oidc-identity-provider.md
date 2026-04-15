---
source: Cloudflare docs
library: cloudflare terraform provider
package: cloudflare
topic: generic oidc identity provider
fetched: 2026-04-15T00:00:00Z
official_docs: https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/generic-oidc/
---

## Required fields
- `account_id`
- `name`
- `type = "oidc"`
- `config.client_id`
- `config.client_secret`
- `config.auth_url`
- `config.token_url`
- `config.certs_url`

## Minimal config snippet
```hcl
resource "cloudflare_zero_trust_access_identity_provider" "generic_oidc" {
  account_id = var.cloudflare_account_id
  name       = "Pocket ID"
  type       = "oidc"

  config = {
    client_id     = var.oidc_client_id
    client_secret = var.oidc_client_secret
    auth_url      = var.oidc_auth_url
    token_url     = var.oidc_token_url
    certs_url     = var.oidc_certs_url
  }
}
```

## Caveats
- Cloudflare’s generic OIDC docs show `pkce_enabled`, `email_claim_name`, `claims`, and `scopes` as optional.
- The provider schema also lists `issuer_url` as an optional config field, but Cloudflare’s generic OIDC setup page does not include it in the required API example.
- Redirect URI must be `https://<team>.cloudflareaccess.com/cdn-cgi/access/callback`.
- Use `type = "oidc"` (not `azureAD`, `saml`, etc.) for generic OIDC.
- SCIM is separate; only enable if you also need provisioning.
