## Why

The repo no longer wants legacy Filebrowser wiring, and the desired replacement (Quantum) is not available as a native nixpkgs service module. At the same time, Cockpit needed both a reliable lifecycle fix and a cleaner long-term access model for `do-admin-1` and `oci-melb-1`.

## What Changes

- Replace legacy `services.admin.filebrowser` wiring with a new `services.admin.quantum` Podman-backed module.
- Rename admin policy/UI references from `filebrowser-admin` to `quantum-admin`.
- Add Quantum OIDC via Pocket ID, keep password fallback declarative, and expose local/remote host data sources over the existing private network model.
- Apply the Cockpit `cockpit-ws-user.service` dependency workaround.
- Standardize Cockpit on per-host sessions exposed as shared-host subpaths (`/do-admin-1`, `/oci-melb-1`) instead of cross-host login chaining.
- Keep Cockpit transport/Tailscale/loopback-TLS concerns owned by the Cockpit module, with host overlays only supplying host-specific values.

## Impact

- Affected capabilities: `admin-services`
- Main code areas:
  - `modules/services/admin/quantum.nix`
  - `modules/services/admin/cockpit.nix`
  - `modules/services/admin/cockpit/*`
  - `modules/services/admin/homepage/data.nix`
  - `modules/applications/admin/default.nix`
  - `modules/applications/admin/identity.nix`
  - `modules/applications/admin/access.nix`
  - `policy/web-services.nix`
  - `hosts/do-admin-1/*`
  - `hosts/oci-melb-1/*`
  - `opentofu/cloudflare/*`

- Resulting behavior:
  - Quantum replaces Filebrowser as the admin file manager.
  - Quantum supports Pocket ID OIDC and host-scoped local/remote sources.
  - Cockpit is available as separate per-host sessions under one public Cockpit host.
  - `do-admin-1` uses trusted local loopback TLS for its Cockpit upstream.
  - `oci-melb-1` is exposed through host-local Tailscale Serve HTTPS rather than direct wide bind assumptions.
