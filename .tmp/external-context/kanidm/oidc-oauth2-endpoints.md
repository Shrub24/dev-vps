---
source: Context7 API
library: Kanidm
package: kanidm
topic: oidc-oauth2-endpoints
fetched: 2026-05-02T00:00:00Z
official_docs: https://github.com/kanidm/kanidm/blob/master/book/src/integrations/oauth2.md
---

## Canonical Kanidm OIDC/OAuth2 endpoint patterns

- **Issuer base**: `https://<kanidm-origin>/oauth2/openid/<client_id>`
- **Discovery**: `https://<kanidm-origin>/oauth2/openid/<client_id>/.well-known/openid-configuration`
- **Authorization**: `https://<kanidm-origin>/oauth2/openid/<client_id>/authorize`
- **Token**: `https://<kanidm-origin>/oauth2/token`
- **UserInfo**: `https://<kanidm-origin>/oauth2/openid/<client_id>/userinfo`

## Origin/path rules

- The **configured origin/domain is the base host**; these endpoints are built from it.
- The **OIDC issuer/discovery/userinfo endpoints add the `/oauth2/openid/<client_id>` path**.
- The **token endpoint does not use the per-client `/openid/<client_id>` path**; it is rooted at `/oauth2/token`.
- For the native OIDC provider, the per-client `client_id` segment is required in the issuer/discovery/userinfo URLs.

## Source confidence

- **High**: Context7 snippets directly show issuer, discovery, userinfo, and token examples from Kanidm docs.
- **Medium**: The exact authorization path is inferred from the documented OAuth2 URL family; verify against the discovery document for a given client if you need absolute runtime confirmation.
