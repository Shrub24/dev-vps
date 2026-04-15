---
source: official docs
library: Termix
package: termix
topic: oidc
fetched: 2026-04-15T00:00:00Z
official_docs: https://docs.termix.site/oidc
---

## Required configuration fields

- **Client ID** — required.
- **Client Secret** — required.
- **Authorization URL** — required; HTTPS URL provided by the OIDC provider.
- **Issuer URL** — required; HTTPS URL identifying the provider.
- **Token URL** — required; HTTPS URL provided by the provider.

## Optional configuration fields

- **User Identifier Path** — default `sub`.
- **Display Name Path** — default `name`.
- **Scopes** — default `openid email profile`.
- **Override User Info URL** — optional; used if user info fetch fails.

## Environment variables

Setting variables takes precedence over stored DB config.

- `OIDC_CLIENT_ID` — required
- `OIDC_CLIENT_SECRET` — required
- `OIDC_ISSUER_URL` — required
- `OIDC_AUTHORIZATION_URL` — required
- `OIDC_TOKEN_URL` — required
- `OIDC_USERINFO_URL` — optional
- `OIDC_IDENTIFIER_PATH` — optional, default `sub`
- `OIDC_NAME_PATH` — optional, default `name`
- `OIDC_SCOPES` — optional, default `openid email profile`

## Redirect / callback URL

- For Keycloak, the docs state the valid redirect URI format is `https://termix.{your-domain}/users/oidc/callback`.
- For Authelia, the docs use the same callback path: `https://termix.{your-domain}/users/oidc/callback`.

## Reverse-proxy / header requirements

- The OIDC page does **not** mention any reverse-proxy header requirements.
- It only states Termix should be configured in admin settings and the provider must accept the callback URL above.

## Minimal actionable wiring guidance for NixOS / podman

- Use a provider that can register the callback URL `https://termix.{your-domain}/users/oidc/callback`.
- Pass the required OIDC values into the container as environment variables, since env vars override DB config.
- Set at least the five required env vars: client ID, client secret, issuer URL, authorization URL, token URL.
- If your provider needs it, set `OIDC_USERINFO_URL`, `OIDC_IDENTIFIER_PATH`, `OIDC_NAME_PATH`, and `OIDC_SCOPES`.
- No additional proxy/header settings are documented on this page.

## Exact cited statements

- “Setting variables will take precedence over the stored DB config.”
- “Variable / Required / Default” table listing `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_ISSUER_URL`, `OIDC_AUTHORIZATION_URL`, `OIDC_TOKEN_URL` as required.
- “Valid redirect URIs: `https://termix.{your-domain}/users/oidc/callback`.”
- “Currently, Termix supports one OIDC provider at a time.”
