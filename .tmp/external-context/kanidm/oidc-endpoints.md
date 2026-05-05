---
source: mixed-web
library: Kanidm
package: kanidm
topic: oidc endpoints
fetched: 2026-05-05T00:00:00Z
official_docs: https://kanidm.com/documentation/
---

## Relevant findings for route-debugging

- I could not verify a public Kanidm 1.9 doc page that explicitly lists the OIDC well-known fields in one place.
- The available Kanidm-related search snippets indicate Kanidm supports OAuth2/OIDC and can be configured per client.
- For debugging an initial redirect failure, the important distinction is:
  - **Issuer / discovery** should be the provider base that serves `/.well-known/openid-configuration`.
  - **Client-specific authorize URLs** are used only after a client is registered; they are not the discovery document itself.
- If Cloudflare is sending users directly to a provider route that does not exist, it is likely using the wrong `authorization_endpoint` value rather than the provider's discovery metadata.

## What to confirm in Kanidm

- `issuer`: provider base URL that owns the discovery document.
- `authorization_endpoint`: must be the real authorize route for the client/provider.
- `token_endpoint`: provider token route.
- `userinfo_endpoint`: provider userinfo route.
- Client-specific endpoints: should be generated under the provider's OIDC/OAuth2 client namespace, not substituted for the well-known endpoints.

## Debug note

A 404 on the first hop usually means Cloudflare was pointed at a non-existent client route instead of the provider's documented authorize endpoint from discovery.
