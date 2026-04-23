---
source: mixed (Termix docs + public search)
library: Termix
package: termix
topic: OIDC troubleshooting for release-2.0.0
aired: 2026-04-17T00:00:00Z
official_docs: https://docs.termix.site/oidc
---

# Termix OIDC troubleshooting (release-2.0.0 focus)

## What the docs require

- `OIDC_CLIENT_ID` (required)
- `OIDC_CLIENT_SECRET` (required)
- `OIDC_ISSUER_URL` (required)
- `OIDC_AUTHORIZATION_URL` (required)
- `OIDC_TOKEN_URL` (required)
- Optional: `OIDC_USERINFO_URL`
- Optional claim paths:
  - `OIDC_IDENTIFIER_PATH` default `sub`
  - `OIDC_NAME_PATH` default `name`
  - `OIDC_SCOPES` default `openid email profile`

The docs also note that env vars override stored DB config.

## Admin-linking behavior

Termix docs say local/OIDC linking is manual:
- Admin Settings → blue chain icon on an OIDC host → enter local username
- Orange chain icon removes the link

If the chain action is missing, the docs imply you may not actually be in the admin settings flow, or the OIDC host/account is not being recognized as linkable.

## Likely failure modes reported in the wild

From public search results, the common pattern is:
- OIDC login succeeds
- UI still shows the user as local/password
- admin/link chain action is absent or ineffective

Most likely causes:
1. Claim mismatch: the IdP does not return the identifier expected by `OIDC_IDENTIFIER_PATH`.
2. Name/email mismatch: the provider does not return the claim Termix uses to resolve the account.
3. Missing env vars or stale DB config: env vars were added after setup but app is still using older stored config.
4. Wrong scopes: provider is not returning `email`, `profile`, or `openid` claims.
5. No userinfo endpoint: if claims are not in the id_token, Termix may need `OIDC_USERINFO_URL`.

## Concrete remediation steps

1. Verify all required env vars are set and restart Termix.
2. Ensure `OIDC_SCOPES='openid email profile'` unless your IdP requires otherwise.
3. Check what claim contains the stable user id; if it is not `sub`, set `OIDC_IDENTIFIER_PATH` accordingly.
4. If display/name mapping fails, set `OIDC_NAME_PATH` to the claim your IdP actually returns.
5. If the IdP only exposes claims via userinfo, set `OIDC_USERINFO_URL`.
6. Re-open Admin Settings and verify the chain-link action appears on the OIDC host entry.
7. If you are on release-2.0.0 and the issue persists, test the next patch release and clear/override stored DB OIDC config with env vars.

## Sources

- https://docs.termix.site/oidc
- https://docs.termix.site/environment-variables
- https://docs.termix.site/docs
- https://github.com/Termix-SSH/Termix/releases
- https://www.cisa.gov/news-events/bulletins/sb26-020
