---
source: Cloudflare official docs
library: Cloudflare One / Access
package: cloudflare-access
topic: generic-oidc-kanidm
fetched: 2026-05-02T00:00:00Z
official_docs: https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/generic-oidc/
---

## Actionable facts for Kanidm + Cloudflare Access generic OIDC

### 1) Redirect/callback URL to register with upstream IdP
Register this exact redirect URI at the upstream OIDC provider:

`https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/callback`

Cloudflare says to use your team name from **Settings → Team name and domain → Team name**.

### 2) What to enter for auth_url, token_url, certs/jwks URL
Cloudflare Access wants these values from the upstream IdP’s OIDC discovery document:

- `auth_url` = the IdP’s `authorization_endpoint`
- `token_url` = the IdP’s `token_endpoint`
- `certs_url` = the IdP’s `jwks_uri`

### 3) Can discovery URL be used instead of separate endpoints?
Yes. Cloudflare says these values can be found on the IdP’s OIDC discovery endpoint / “well-known URL”.

### 4) PKCE / client type gotchas
- PKCE is optional in Cloudflare Access generic OIDC.
- If enabled, PKCE runs on **all login attempts**.
- Only enable it if the IdP supports PKCE.
- Cloudflare’s generic OIDC setup expects a standard client/app with client ID + client secret.

## Exact Cloudflare doc URL
https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/generic-oidc/

## Related Cloudflare SaaS OIDC doc (not upstream IdP config)
https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/saas-apps/generic-oidc/
