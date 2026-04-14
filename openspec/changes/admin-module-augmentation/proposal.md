## Why

The admin application currently wires only Termix, which leaves key host-operations tools scattered or absent during early fleet bring-up. This change expands the admin baseline with native NixOS services so operators can manage hosts through a consistent, private, Tailscale-first control surface.

**Core Value:** provide a reproducible, low-complexity admin toolbox for first-host reliability while preserving fleet growth patterns.

## What Changes

- Extend `modules/applications/admin.nix` to include additional native admin services from nixpkgs.
- Add baseline enablement and minimal configuration for:
  - Cockpit (`services.cockpit`)
  - Webhook (`services.webhook`)
  - Ntfy (`services.ntfy-sh`)
  - Gatus (`services.gatus`) replacing Uptime Kuma
  - Vaultwarden (`services.vaultwarden`)
  - Filebrowser (`services.filebrowser`)
  - Homepage Dashboard (`services.homepage-dashboard`)
  - Beszel hub (`services.beszel.hub`)
- Enable Cockpit plugins focused on your immediate operations priority:
  - Podman management (`cockpit-podman`)
  - Core file/storage-adjacent visibility (`cockpit-files`) with baseline service/system views
- Add Cockpit-only Tailscale Serve exposure in this change; defer broader admin HTTP routing to upcoming Tailscale-backed Caddy wiring.
- Defer L1 cross-host log syncing to a follow-up change; central operational visibility in this stage comes from Cockpit + Beszel surfaced via Homepage.
- Keep state-path mapping low-risk in baseline wiring (prefer module-safe defaults where hardening/state-directory behavior is tightly coupled).
- Keep exposure private and aligned with existing Tailscale-first constraints (no new public ingress baseline).

## Capabilities

### New Capabilities
- _(none)_

### Modified Capabilities
- `admin-services`: expand the admin-service contract to include Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Filebrowser, Homepage Dashboard, and Beszel hub wiring, with log-sync deferred.

## Impact

- Affected code:
  - `modules/applications/admin.nix`
  - (if needed) supporting service modules under `modules/services/`
  - host composition files that consume `applications.admin`
- Affected behavior:
  - admin host profile starts additional service units
  - cockpit gains podman + operational views for day-2 host management
  - cockpit is the only newly exposed admin web surface (private via Tailscale Serve)
  - broader internal operations surface remains private-first
- Validation surface:
  - minimal wiring-first assertions in phase/admin contract tests
  - `nix flake check`
