---
source: Cloudflare docs
library: Cloudflare Access
package: cloudflare-access
topic: generic oidc debug
fetched: 2026-05-05T00:00:00Z
official_docs: https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/generic-oidc/
---

## Cloudflare Access OIDC IdP fields

Configured in **Zero Trust → Integrations → Identity providers → Add new identity provider → OpenID Connect**:

- **Name**: arbitrary label
- **Client ID**: from the provider app/client
- **Client secret**: from the provider app/client
- **Auth URL**: provider `authorization_endpoint`
- **Token URL**: provider `token_endpoint`
- **Certificate URL**: provider `jwks_uri`
- **PKCE**: optional, only if supported
- **Scopes / claims**: optional

## What comes from provider metadata vs manual URL

From the provider's **well-known** document:

- `authorization_endpoint` → Cloudflare **Auth URL**
- `token_endpoint` → Cloudflare **Token URL**
- `jwks_uri` → Cloudflare **Certificate URL**
- issuer/discovery are used only to discover those values

Manually configured in the provider app:

- **Authorized redirect URI / callback** must be Cloudflare's callback:
  `https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/callback`

## Route-not-found debugging takeaway

For the initial redirect, Cloudflare should **not** be pointed at a generic `/ui/oauth2` path unless that path is literally the provider's discovered `authorization_endpoint`.

Cloudflare sends the provider a normal OIDC auth request and expects the provider to redirect back to Cloudflare's callback URL above.

If the browser lands on a 404 before login, the likely bug is a mismatched **Auth URL** in Cloudflare, not the redirect URI back to Cloudflare.
