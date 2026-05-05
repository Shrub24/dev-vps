---
source: Context7 API + official Kanidm docs
library: Kanidm
package: kanidm
topic: oauth2-endpoints
fetched: 2026-05-02T00:00:00Z
official_docs: https://kanidm.github.io/kanidm/stable/integrations/oauth2.html
---

# Kanidm OAuth2/OIDC endpoints

## Global (not client-specific)
- Authorization endpoint: `https://idm.example.com/oauth2/authorise`
- Token endpoint: `https://idm.example.com/oauth2/token`
- Discovery (recommended): `https://idm.example.com/oauth2/openid/:client_id:/.well-known/openid-configuration`
- OAuth 2.0 metadata: `https://idm.example.com/oauth2/openid/:client_id:/.well-known/oauth-authorization-server`

## Client-specific
- OIDC issuer: `https://idm.example.com/oauth2/openid/:client_id:`
- UserInfo: `https://idm.example.com/oauth2/openid/:client_id:/userinfo`
- JWKS / signing public key: `https://idm.example.com/oauth2/openid/:client_id:/public_key.jwk`
- WebFinger (discouraged): `https://idm.example.com/oauth2/openid/:client_id:/.well-known/webfinger`

## Notes
- Kanidm states OAuth2/OIDC URLs are client-specific for issuer, endpoint URLs, and token signing keys.
- The discovery document is the preferred way to obtain all required endpoints.
- For Cloudflare Access generic OIDC, use the discovery URL and the client-specific issuer/JWKS derived from it.
- The docs do not show a separate `/certs` endpoint; the JWK endpoint is `public_key.jwk`.
