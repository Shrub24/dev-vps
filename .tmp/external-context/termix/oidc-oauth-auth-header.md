---
source: official docs / source search
library: Termix
package: termix
topic: oidc-oauth-auth-header
fetched: 2026-04-15T00:00:00Z
official_docs: https://termix.app
---

Confirmed from official Termix site:

- No native OIDC/OAuth configuration keys are documented on the public site.
- No reverse-proxy auth header support is documented on the public site.

Unconfirmed:

- Any env vars such as `OIDC_*`, `OAUTH_*`, `AUTH_HEADER`, `TRUSTED_AUTH_HEADER`, or similar.
- Any documented callback/redirect URL or provider client settings.

Minimal safe posture for OpenSpec:

- Treat Termix as lacking documented native SSO integration unless source code or a vendor doc explicitly confirms it.
- If fronting it with an auth proxy, require explicit upstream header handling to be verified before trusting identity headers.
- Prefer a separate, well-documented auth gateway rather than assuming Termix can consume OIDC directly.
