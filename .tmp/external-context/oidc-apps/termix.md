---
source: mixed official docs + repository evidence
library: Termix
package: Termix-SSH/Termix
topic: oidc redirect callback scopes claims
fetched: 2026-05-02T00:00:00Z
official_docs: https://docs.termix.site
---
- Redirect/callback: `/users/oidc/callback` on the app origin. Termix builds `backendCallbackUri = <origin>/users/oidc/callback`.
- Issuer/discovery: issuer URL is used; discovery is attempted from `issuer_url/.well-known/openid-configuration`.
- Scopes: default `openid email profile` (`OIDC_SCOPES` / config `scopes`).
- Claims/fields: `identifier_path` defaults to `sub`; `name_path` defaults to `name`; `userinfo_url` is optional; `allowed_users` can restrict logins.
- Caveat: Termix supports either issuer discovery or explicit `authorization_url`/`token_url`; if discovery fails, you may need to supply endpoints manually.

Sources:
- https://github.com/Termix-SSH/Termix/blob/main/src/backend/database/routes/users.ts
- https://github.com/Termix-SSH/Termix/blob/main/src/backend/database/db/schema.ts
- https://github.com/Termix-SSH/Termix/blob/main/src/backend/database/routes/users.ts#L809
- https://docs.termix.site/
