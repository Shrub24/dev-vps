## 1. Scope and Ownership Alignment

- [ ] 1.1 Confirm split ownership in artifacts: `cloudflare-opentofu-control-plane` owns Cloudflare resources; this change owns Nix/runtime behavior
- [x] 1.2 Confirm canonical policy map path/schema at `policy/web-services.nix` for cross Nix/OpenTofu consumption
- [ ] 1.3 Define phase-1 supported app set for Cloudflare Access OIDC (`gatus`, `filebrowser`, `beszel`, `termix`) in OpenSpec artifacts
- [ ] 1.4 Capture explicit exception set for this phase (`vaultwarden`, `syncthing`, `webhook`, `ntfy`, `cockpit`, `homepage`) with rationale
- [ ] 1.5 Define host-scoped secret naming/template plan for Cloudflare OIDC client credentials on `do-admin-1`

## 2. App-level OIDC Wiring

- [ ] 2.1 Wire Cloudflare Access OIDC settings for Gatus in `modules/applications/admin.nix`
- [ ] 2.2 Wire Cloudflare Access OIDC settings for Filebrowser in `modules/applications/admin.nix`
- [ ] 2.3 Wire Cloudflare Access OIDC settings for Beszel in `modules/applications/admin.nix`
- [ ] 2.4 Wire Cloudflare Access OIDC settings for Termix in `modules/applications/admin.nix`
- [ ] 2.5 Ensure Homepage remains Access-gated only (no app-auth changes in this change)

## 3. Route/Posture Policy Updates

- [x] 3.1 Preserve Access-gated admin defaults in edge route declarations for applicable admin services
- [x] 3.2 Update Vaultwarden route policy as explicit phase-1 exception (no Cloudflare Access/OIDC coupling in-app)
- [x] 3.3 Update music/Navidrome route posture to reflect grey-cloud DNS intent and non-reliance on Cloudflare WAF
- [ ] 3.4 Consume control-plane exception inputs (global defaults + host/route overrides) without defining Cloudflare resources in this change
- [x] 3.5 Ensure runtime route/auth behavior is sourced from canonical `policy/web-services.nix` fields (not duplicated ad-hoc declarations)

## 4. CrowdSec Baseline

- [ ] 4.1 Add CrowdSec baseline enablement for `do-admin-1`
- [ ] 4.2 Connect CrowdSec acquisition/parsing to relevant ingress/service logs
- [ ] 4.3 Add conservative default remediation profile suitable for admin/music exposure mix

## 5. Contracts, Validation, and Rollout

- [ ] 5.1 Update `tests/phase-do-admin-contract.sh` for app auth posture assertions (OIDC-supported vs exceptions)
- [x] 5.2 Update `tests/phase-05-edge-ingress-contract.sh` for Access-gate + exception + music posture expectations
- [x] 5.3 Run validation commands (`bash tests/phase-do-admin-contract.sh`, `bash tests/phase-05-edge-ingress-contract.sh`, and scoped eval checks)
- [ ] 5.4 Run `openspec validate cloudflare-access-oidc-crowdsec-navidrome --strict`
- [ ] 5.5 Deploy to `do-admin-1` and verify: app login paths, route behavior, and CrowdSec baseline activity
