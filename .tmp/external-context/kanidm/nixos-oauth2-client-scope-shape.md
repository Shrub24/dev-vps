---
source: mixed docs
library: Kanidm
package: kanidm
topic: nixos oauth2 client scope shape
fetched: 2026-05-05T00:00:00Z
official_docs: https://kanidm.github.io/kanidm/master/integrations/oauth2.html
---

## Debug-relevant findings for `requested scopes {openid,email,profile} available scopes {}`

- `services.kanidm.provision.systems.oauth2` is an **attribute set of submodules**.
- Per OAuth2 client, both `scopeMaps` and `supplementaryScopeMaps` are **attribute sets of lists of strings**.
- `claimMaps` is also an **attribute set of submodules**, not a list.

### Exact shape

For each client entry under `services.kanidm.provision.systems.oauth2.<name>`:

- `scopeMaps = { <kanidm-group> = [ "openid" "email" "profile" ]; }`
- `supplementaryScopeMaps = { <kanidm-group> = [ "admin" ]; }`
- `claimMaps = { <map-name> = { joinType = "array" | "csv" | "ssv"; valuesByGroup = { <kanidm-group> = [ "claim-value" ]; }; }; }`

### Runtime pitfall that matches empty available scopes

Kanidm requires the **requested scopes to be present in the final granted scope set**. If no group in `scopeMaps` contributes `openid` (or the requested scopes are mapped only in `supplementaryScopeMaps`), runtime can show `available scopes {}` and the auth request fails.

### Another common mismatch

`claimMaps` do **not** grant OAuth scopes. They only add claims/values. Putting `openid`, `email`, or `profile` under `claimMaps` will not populate available scopes.

### Minimal working pattern for OIDC

- Put `openid` in `scopeMaps` for at least one allowed Kanidm group.
- Add `email` / `profile` there too if the client requests them.
- Use `supplementaryScopeMaps` only for non-authorizing optional scopes.
- Use `claimMaps` only for claim enrichment.

### Canonical Kanidm CLI equivalence

- `kanidm system oauth2 update-scope-map <name> <group> openid email profile`
- `kanidm system oauth2 update-sup-scope-map <name> <group> admin`
- `kanidm system oauth2 update-claim-map ...` for claims, not scopes.
