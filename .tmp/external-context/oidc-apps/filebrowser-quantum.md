---
source: official docs + repository evidence
library: FileBrowser Quantum
package: gtsteffaniak/filebrowser
topic: oidc redirect callback scopes claims
fetched: 2026-05-02T00:00:00Z
official_docs: https://filebrowserquantum.com/en/docs/configuration/authentication/oidc/
---
- Redirect/callback: `/api/auth/oidc/callback` appended to the configured base URL. If `baseURL` has a subpath, append it there too.
- Issuer/discovery: issuer URL is used via `issuerUrl`; examples show both provider-specific issuer paths and base issuer URLs.
- Scopes: default `openid email profile`; docs say add group scopes if you need group claims.
- Claims/fields: `userIdentifier` defaults to `preferred_username`; `groupsClaim` defaults to `groups`; `adminGroup` and `userGroups` can gate access by group.
- Caveat: docs recommend OIDC-compliant providers only; `userGroups` requires v1.3.x+; `createUser` is deprecated and should be omitted.

Sources:
- https://filebrowserquantum.com/en/docs/configuration/authentication/oidc/
- https://github.com/gtsteffaniak/filebrowser/blob/main/backend/common/settings/auth.go
