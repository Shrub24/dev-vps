## 1. Canonical route and Syncthing wiring

- [x] 1.1 Update `policy/web-services.nix` so Syncthing admin uses the shared `syncthing` hostname with a host-specific subpath for `oci-melb-1`, following the existing path-based admin route pattern.
- [x] 1.2 Adjust Syncthing/runtime ingress wiring as needed so reverse-proxy access works through the declared subpath while the GUI remains private-origin reachable on the host.

## 2. Route consumers and operator surface

- [x] 2.1 Update any route consumers or admin links that assume the old root Syncthing URL so they resolve to the new canonical subpath URL.
- [x] 2.2 Verify the pattern remains reusable for future Syncthing hosts without requiring a different exposure model.

## 3. Validation

- [x] 3.1 Run targeted evaluation checks for resolved Syncthing public URL, ingress route rendering, and any Syncthing-specific route settings introduced by the change.
- [x] 3.2 Run repo validation (`nix flake check` in the appropriate source mode and any targeted evals needed for the touched modules).
- [x] 3.3 Run `openspec validate add-syncthing-subpath-webuis --strict` and confirm the change is ready for implementation.
