## Overview

This change finishes two related admin-surface migrations:

1. Replace legacy Filebrowser wiring with Quantum.
2. Restore and simplify Cockpit so each host has a stable private-first session model.

The final design intentionally reflects the implemented end state only, not the intermediate troubleshooting paths explored during development.

## Final Architecture

### Quantum
- Implemented as `services.admin.quantum` in `modules/services/admin/quantum.nix`.
- Runs as a Podman/OCI container.
- Persists state under `${applications.admin.dataRoot}/quantum`.
- Uses Pocket ID OIDC for primary auth, with declarative password fallback still available.
- Exposes:
  - local `do-admin-1` data via direct local source paths,
  - remote host data (`oci-melb-1`, `arch`) via SSHFS-over-Tailscale mounts.
- Keeps host-specific source wiring in `hosts/do-admin-1/quantum.nix`.

### Cockpit
- Implemented as `services.admin.cockpit` with focused helper submodules:
  - `modules/services/admin/cockpit/loopback-tls.nix`
  - `modules/services/admin/cockpit/tailscale-serve.nix`
- Applies the upstream `cockpit-ws-user.service` dependency workaround.
- Uses per-host sessions instead of Cockpit login-page host chaining.
- Public UX is a shared Cockpit host with per-host subpaths:
  - `/do-admin-1`
  - `/oci-melb-1`
- `do-admin-1` route:
  - proxied locally to Cockpit over HTTPS on loopback,
  - trusted via a host-local private CA and generated loopback leaf cert.
- `oci-melb-1` route:
  - exposed through host-local `tailscale serve --https=9443`,
  - consumed by do-admin-1 as a tailscale-upstream HTTPS origin.
- Host overlays only provide host-specific values such as service-user secret, public host, `UrlRoot`, and whether Tailscale Serve / loopback TLS are enabled.

## Key Decisions

### 1. Quantum uses OCI container wiring
- Quantum is not maintained here as a native nixpkgs service.
- OCI wiring matches existing repo patterns and keeps runtime explicit.

### 2. Quantum local and remote sources stay host-owned
- The service module owns the generic source/mount model.
- `hosts/do-admin-1/quantum.nix` owns concrete source paths and remote host definitions.
- This preserves single-source ownership for operator-tuned paths.

### 3. Cockpit uses per-host sessions, not remote chaining
- The final supported model is direct per-host sessions.
- This removes fragile cross-host login behavior and keeps auth local to each host.

### 4. Cockpit transport concerns stay under Cockpit ownership
- Tailscale Serve, loopback TLS generation, route-derived public host handling, and socket bind behavior belong to the Cockpit module family.
- Application access modules and host defaults should not duplicate Cockpit transport logic.

### 5. Trusted local CA replaces long-term skip-verify for do-admin-1
- `do-admin-1` keeps HTTPS to the local Cockpit upstream.
- A generated private CA and loopback leaf cert are installed declaratively.
- Caddy trusts the generated public CA copy rather than using `tls_insecure_skip_verify` in the steady-state design.

## Non-Goals

- Homepage-authenticated Quantum widget integration.
- Reintroducing Cockpit remote-host login chaining.
- Broad redesign of unrelated admin composition.

## Operational Notes

- `do-admin-1` and `oci-melb-1` must each deploy their host-specific Cockpit overlays.
- `do-admin-1` owns the public edge route and local loopback-TLS trust chain.
- `oci-melb-1` owns its local Cockpit service-user and Tailscale Serve exposure.
