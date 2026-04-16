## 1. Pivot and Scope Alignment

- [x] 1.1 Update OpenSpec artifacts in place for Cloudflare-first pivot (Access + Pocket ID retained)
- [x] 1.2 Confirm ownership split remains: `cloudflare-opentofu-control-plane` owns Cloudflare resources; this change owns Nix/runtime behavior
- [x] 1.3 Confirm explicit exception posture: `pocket-id` (no Access), `navidrome` (no Access + no CDN cache), `vaultwarden` (phase exception)

## 2. Identity Model (Retained)

- [x] 2.1 Keep Cloudflare Access upstream IdP on Pocket ID generic OIDC (control-plane apply verification; tracked here, implemented in OpenTofu Cloudflare layer)
- [x] 2.2 Keep phase-1 app OIDC wiring on Pocket ID for `gatus`, `beszel`, `termix`
- [x] 2.3 Ensure `homepage` remains Access-gated only (no app-native OIDC in this phase)
- [x] 2.4 Keep file-management UI out of this phase OIDC rollout

## 3. Route and Exposure Posture

- [x] 3.1 Enforce orange-cloud posture by default for in-scope exposed routes (control-plane apply verification)
- [x] 3.2 Keep Pocket ID route as explicit orange-cloud, non-Access-gated exception (IdP loop avoidance; control-plane apply verification)
- [x] 3.3 Keep Navidrome route orange-cloud, non-Access-gated, with CDN/caching disabled
- [x] 3.4 Keep Vaultwarden as explicit phase exception (no Access move in this pivot; control-plane apply verification)
- [x] 3.5 Ensure route/auth behavior is sourced from canonical `policy/web-services.nix` fields

## 4. Security Baseline (Cloudflare-first)

- [x] 4.1 Keep CrowdSec and firewall bouncer removed from host-layer rollout scope
  - [x] 4.1.a Remove remaining CrowdSec checks from active contract scripts
  - [x] 4.1.b Keep CrowdSec mentions only as contextual references in current/archived OpenSpec docs
- [x] 4.2 Define Cloudflare firewall/WAF/traffic controls as primary blocking layer for exposed traffic
- [x] 4.3 Keep bypass/non-Access route classes explicit and minimal in policy and tests

## 5. Contracts, Validation, and Rollout

- [x] 5.1 Update `tests/phase-05-edge-ingress-contract.sh` for orange-cloud defaults + explicit exceptions + Navidrome no-cache posture
- [x] 5.2 Update `tests/phase-do-admin-contract.sh` for retained Pocket ID app-auth posture and exception set
- [x] 5.3 Run validation commands (`bash tests/phase-do-admin-contract.sh`, `bash tests/phase-05-edge-ingress-contract.sh`, and scoped eval checks)
- [x] 5.4 Run `openspec validate cloudflare-access-oidc-crowdsec-navidrome --strict`
- [x] 5.5 Deploy to `do-admin-1` and verify Access login (Pocket ID upstream), app login paths, orange-cloud behavior, and Navidrome streaming posture (runtime apply verification)
