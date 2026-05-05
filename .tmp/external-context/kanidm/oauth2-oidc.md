---
source: official docs
library: Kanidm
package: kanidm
topic: oauth2-oidc
fetched: 2026-05-02T00:00:00Z
official_docs: https://kanidm.github.io/kanidm/master/integrations/oauth2.html
---

## Repo-relevant conclusions

- Use the per-client OIDC Discovery URL when the client supports it; Kanidm explicitly recommends Discovery / OAuth 2.0 Authorization Server Metadata over WebFinger.
- The discovery document is client-specific and includes the client’s endpoints and signing keys.
- The issuer URL is also client-specific: `https://idm.example.com/oauth2/openid/:client_id:`.
- The well-known Discovery URL is client-specific: `https://idm.example.com/oauth2/openid/:client_id:/.well-known/openid-configuration`.
- The OAuth 2.0 AS metadata URL is client-specific too: `.../.well-known/oauth-authorization-server`.
- The authorization endpoint is global: `https://idm.example.com/oauth2/authorise`.
- The token endpoint is global: `https://idm.example.com/oauth2/token`.
- The userinfo endpoint is client-specific: `https://idm.example.com/oauth2/openid/:client_id:/userinfo`.
- The JWKS/public key endpoint is client-specific: `https://idm.example.com/oauth2/openid/:client_id:/public_key.jwk`.
- Different clients must not share a single OAuth2 client definition; Kanidm treats multiple redirect URLs as supplemental URLs for the same app only.
- WebFinger is discouraged because it cannot distinguish client IDs and Kanidm uses client-specific issuer/endpoint/key sets.

## Implementation note for this repo

Prefer configuring OIDC consumers from the per-client discovery URL, not by wiring endpoints manually, unless a client cannot consume discovery. Treat the authorize/token endpoints as shared Kanidm endpoints, but treat issuer, discovery, userinfo, and JWKS/public-key URLs as client-bound.
