---
source: official docs + repository evidence
library: Karakeep
package: karakeep-app/karakeep
topic: oidc redirect callback scopes claims
fetched: 2026-05-02T00:00:00Z
official_docs: https://docs.karakeep.app/configuration
---
- Redirect/callback: `/api/auth/callback/custom` appended to `NEXTAUTH_URL` / app base URL.
- Issuer/discovery: discovery URL is used via `OAUTH_WELLKNOWN_URL` (openid-configuration URL).
- Scopes: default `openid email profile` (`OAUTH_SCOPE`).
- Claims/fields: no app-specific claim mapping documented in the config docs; NextAuth custom provider is used.
- Caveats: only OIDC-compliant OAuth providers are supported; `OAUTH_AUTO_REDIRECT` can skip the login page when OAuth is the only auth method; `OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING` should be enabled only if the provider is trusted.

Sources:
- https://docs.karakeep.app/configuration
- https://github.com/karakeep-app/karakeep/blob/main/docs/versioned_docs/version-v0.31.0/03-configuration/01-environment-variables.md
- https://github.com/karakeep-app/karakeep/blob/main/docs/versioned_docs/version-v0.31.0/03-configuration.md
