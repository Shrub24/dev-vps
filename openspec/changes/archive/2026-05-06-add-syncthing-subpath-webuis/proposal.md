## Why

Syncthing on `oci-melb-1` is syncing correctly, but its GUI is bound to `127.0.0.1:8384`, which makes browser access awkward for routine administration. We want a simple private-first way to reach host Syncthing UIs through the existing edge policy model without widening Syncthing's bind scope to `0.0.0.0`.

## What Changes

- Add declarative private admin routing for Syncthing web UIs using the existing `policy/web-services.nix` path-based route pattern.
- Support a shared `syncthing.shrublab.xyz` admin surface with host-specific subpaths such as `/oci-melb-1/`.
- Keep Syncthing GUIs private on each host's tailnet-reachable interface while making reverse-proxied access work correctly behind a subpath-aware configuration.
- Reuse existing edge-ingress and policy resolution patterns so future Syncthing hosts can be added without inventing a separate exposure model.

## Capabilities

### New Capabilities
- `syncthing-admin-access`: private, path-based browser access to per-host Syncthing web UIs through the canonical web policy and ingress model.

### Modified Capabilities
- `network-access`: add an explicit private-origin route pattern for host-specific Syncthing admin subpaths under a shared admin hostname.
- `admin-services`: define that Syncthing admin access remains private-first and may be exposed through shared subpath browser entrypoints while keeping host-local GUIs loopback-bound.

## Impact

- Affected policy/runtime files will likely include `policy/web-services.nix`, route consumers under `modules/services/edge-proxy-ingress.nix`, and Syncthing service wiring.
- Browser access for Syncthing administration will move from SSH tunneling/manual localhost access to declared reverse-proxied private routes.
- Homepage/admin links may need to target the new canonical Syncthing route shape.
