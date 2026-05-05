---
source: Context7 API + official source
library: Nixpkgs / Kanidm
package: kanidm
topic: provisioning semantics
fetched: 2026-05-05T00:00:00Z
official_docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/security/kanidm.nix
---

## Relevant semantics

- `services.kanidm.provision.persons.<name>.groups` is the source of truth for which groups a person should belong to.
- `services.kanidm.provision.groups.<name>.members` is derived from persons when declared in nixpkgs (`config.members = ... personCfg.groups ...`).
- `overwriteMembers = true` means the group member list is rewritten to match the declared list.
- `overwriteMembers = false` means append mode: interactive/manual members can remain, and future member removals are not reflected automatically.
- The provisioning tool tracks created entities for auto-removal, but append mode explicitly disables automatic reflection of removals in group membership.

## Practical takeaway

If a person is removed from a group's `persons.<name>.groups`, the declarative model intends that membership to be removed on reprovision **only when the group is being overwritten**. In append mode, removals are not automatically applied.

## Recommendation for this repo

Use `overwriteMembers = true` for Kanidm groups whose membership should follow person declarations exactly. Avoid relying on `members = []` + `overwriteMembers = false` if you need removals to propagate from the person side; that pattern preserves extra/manual members and will not make person-side membership fully authoritative for deletions.
