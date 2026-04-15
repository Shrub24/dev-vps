## Why

We are keeping Cloudflare Access as the auth provider while splitting ownership cleanly: canonical service/subdomain policy lives in `policy/web-services.nix`, Cloudflare resources are managed in `cloudflare-opentofu-control-plane`, and this change handles Nix/runtime behavior on `do-admin-1`.

**Core Value:** keep Cloudflare and Nix in sync through clear ownership boundaries while preserving explicit security exceptions.

## What Changes

- Depend on canonical policy map `policy/web-services.nix` and `cloudflare-opentofu-control-plane` outputs for DNS/Access posture.
- Keep Cloudflare Access route gating in place for admin routes by default.
- Configure supported apps to use Cloudflare Access as OIDC provider (first wave: `gatus`, `filebrowser`, `beszel`, `termix`).
- Keep exceptions explicit:
  - `homepage`: Access-gated only (no app-level auth work in this change)
  - `vaultwarden`: exception path in this phase (no Cloudflare Access OIDC rollout in-app)
- Add CrowdSec baseline on `do-admin-1` as a second-layer protective control for exposed/bypassed traffic classes.
- Align music/Navidrome route posture with grey-cloud DNS and route policy that does not assume Cloudflare Access/WAF controls.
- Consume ingress policy knobs from canonical policy map for global defaults plus explicit host/route exceptions.
- Add/adjust contract checks for route/auth posture and security baseline behavior.

## Capabilities

### Modified Capabilities
- `admin-services`: support Cloudflare Access OIDC integration for selected admin apps, with explicit exception handling where app/client behavior requires it.
- `edge-proxy-ingress`: preserve Access-gated admin defaults while consuming explicit host/route policy exceptions declared by control-plane ownership.
- `network-access`: reinforce that public exposure decisions remain explicit and service-specific.

## Impact

- Affected code (expected):
  - `policy/web-services.nix`
  - `modules/applications/admin.nix`
  - `modules/services/edge-proxy-ingress.nix`
  - `hosts/do-admin-1/default.nix`
  - `tests/phase-do-admin-contract.sh`
  - `tests/phase-05-edge-ingress-contract.sh`
  - `tests/phase-06-applications-contract.sh` (if needed for CrowdSec/app auth assertions)
- Affected systems:
  - `do-admin-1`
  - Cloudflare control plane managed by `cloudflare-opentofu-control-plane`
- Dependencies:
  - `policy/web-services.nix`
  - `openspec/changes/cloudflare-opentofu-control-plane`
  - Existing Cloudflare Access + edge-ingress policy model
  - Host-scoped SOPS secrets for OIDC client credentials
