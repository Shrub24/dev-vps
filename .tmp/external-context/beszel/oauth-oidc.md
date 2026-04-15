---
source: official docs
library: Beszel
package: beszel
topic: oauth-oidc-env-and-callback
fetched: 2026-04-15T00:00:00Z
official_docs: https://beszel.dev/guide/oauth
---

Confirmed keys from Beszel docs:

- `DISABLE_PASSWORD_AUTH=true` — disables password login in the hub.
- `USER_CREATION=true` — enables automatic user creation for OAuth2 / OIDC.

Callback/redirect URL expectation:

- Use `<your-beszel-url>/api/oauth2-redirect` as the OAuth2/OIDC callback/redirect URL.

Important note:

- The docs do **not** confirm any environment variable for provider client ID/secret/issuer settings.
- Provider configuration is done in the PocketBase `users` collection UI under OAuth2 provider settings.
