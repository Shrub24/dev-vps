## Why

We are pivoting to a Cloudflare-first edge posture: keep Cloudflare Access for browser-route gating, keep Pocket ID as the shared identity source (including Access upstream IdP), move to full orange-cloud exposure posture, and remove CrowdSec from host-layer controls.

**Core Value:** simplify edge security by consolidating identity and traffic protection at Cloudflare while keeping route exceptions explicit.

## What Changes

- Keep Cloudflare Access route gating for admin browser routes by default.
- Keep Pocket ID as shared OIDC issuer for selected admin apps (`gatus`, `beszel`, `termix`) and as Cloudflare Access upstream generic OIDC IdP.
- Keep canonical policy ownership split:
  - `policy/web-services.nix` is canonical service/subdomain policy
  - `cloudflare-opentofu-control-plane` owns Cloudflare resources and enforcement knobs
- Move to full orange-cloud route posture for exposed services in this scope.
- Keep explicit exceptions:
  - `pocket-id`: orange-cloud, not Access-gated (to avoid Access→IdP loop)
  - `navidrome`: orange-cloud, not Access-gated, CDN/caching disabled for streaming
  - `vaultwarden`: remains explicit phase exception (not moved behind Access in this pivot)
- Keep `homepage` as Access-gated only (no app-native OIDC work in this phase).
- Keep file-management UI out of this phase’s OIDC rollout.
- Remove CrowdSec and firewall bouncer from rollout scope; rely on Cloudflare traffic blocking and firewall controls at the edge.
- Update contract checks for orange-cloud posture, Access-vs-exception behavior, and Cloudflare-first security baseline.

## Capabilities

### Modified Capabilities
- `admin-services`: keep Pocket ID app OIDC integration for selected apps and maintain explicit exception posture.
- `edge-proxy-ingress`: enforce Access-gated defaults with explicit bypass exceptions under full orange-cloud policy intent.
- `network-access`: define Cloudflare edge firewall/traffic controls as primary blocking layer for this rollout.

## Impact

- Affected code (expected):
  - `policy/web-services.nix`
  - `modules/applications/admin.nix`
  - `modules/services/pocket-id.nix`
  - `modules/services/termix.nix`
  - `modules/services/edge-proxy-ingress.nix`
  - `hosts/do-admin-1/default.nix`
  - `opentofu/cloudflare/main.tf`
  - `opentofu/cloudflare/variables.tf`
  - `opentofu/cloudflare/outputs.tf`
  - `opentofu/cloudflare/terraform.tfvars.example`
  - `tests/phase-do-admin-contract.sh`
  - `tests/phase-05-edge-ingress-contract.sh`
  - `tests/phase-06-applications-contract.sh` (if needed)
- Affected systems:
  - `do-admin-1`
  - Cloudflare control plane managed by `cloudflare-opentofu-control-plane`
- Dependencies:
  - `policy/web-services.nix`
  - `openspec/changes/cloudflare-opentofu-control-plane`
  - Existing Cloudflare Access + edge-ingress policy model
  - Host-scoped SOPS secrets for OIDC credentials
