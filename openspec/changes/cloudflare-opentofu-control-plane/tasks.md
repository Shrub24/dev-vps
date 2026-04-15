## 1. Control-Plane Scope and Layout

- [x] 1.1 Create canonical policy map path and schema at `policy/web-services.nix`
- [x] 1.2 Define OpenTofu Cloudflare control-plane directory/layout and ownership boundaries around the canonical map
- [x] 1.3 Define JSON export flow from canonical map to `generated/policy/web-services.json`
- [x] 1.4 Define global Access/AOP default policy model
- [x] 1.5 Define explicit per-host and per-route exception schema

## 2. Cloudflare Policy Declarations

- [x] 2.1 Declare initial host policy for `do-admin-1` admin routes
- [x] 2.2 Declare music/Navidrome as grey-cloud route class
- [x] 2.3 Define how Vaultwarden policy exception is represented at control-plane level

## 3. Runtime Consumer Contract

- [x] 3.1 Define Nix/runtime consumption contract from `policy/web-services.nix`
- [x] 3.2 Define OpenTofu consumption contract from generated JSON
- [x] 3.3 Align contracts with `cloudflare-access-oidc-crowdsec-navidrome` dependency expectations

## 4. Validation

- [x] 4.1 Add/adjust OpenSpec spec deltas for control-plane capability and network-access boundaries
- [x] 4.2 Add drift guard to verify generated JSON matches canonical policy map
- [x] 4.3 Run `openspec validate cloudflare-opentofu-control-plane --strict`
