---
source: mixed (public search)
library: Termix
package: termix
topic: release-2.0.0 notes and OIDC-related checks
aired: 2026-04-17T00:00:00Z
official_docs: https://github.com/Termix-SSH/Termix/releases
---

# Termix release-2.0.0 notes (OIDC-related)

Public search did not surface a release-2.0.0-specific OIDC bug report, but the current release stream shows OIDC-related changes such as a "remember me" toggle.

## Practical takeaway

If OIDC works but the account still behaves like a local/password user:
- treat it as a claim/configuration issue first
- verify admin-linking in the UI
- compare your IdP claims against `OIDC_IDENTIFIER_PATH` and `OIDC_NAME_PATH`

## Source links

- https://github.com/Termix-SSH/Termix/releases
- https://docs.termix.site/oidc
- https://docs.termix.site/environment-variables
