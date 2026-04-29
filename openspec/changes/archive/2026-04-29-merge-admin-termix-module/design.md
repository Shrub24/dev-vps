## Context

The repository already defines admin services as service-owned modules under `modules/services/admin/`, and the archived admin split change established that as the target structure. Termix is an outlier because the actual implementation remains in `modules/services/termix.nix` while `modules/services/admin/termix.nix` only forwards `services.admin.termix.enable` into `services.termix.enable`. Admin identity wiring also writes runtime settings into `services.termix`, which preserves the old split instead of the intended ownership boundary.

## Goals / Non-Goals

**Goals:**
- Make `modules/services/admin/termix.nix` the single canonical Termix module.
- Move Termix options and runtime wiring under `services.admin.termix`.
- Preserve existing Termix behavior, data layout, OIDC wiring, and systemd/podman service names.

**Non-Goals:**
- Changing Termix exposure policy, ports, or container images.
- Renaming generated Podman units or altering tailscale serve integration.
- Refactoring unrelated admin services.

## Decisions

- **Keep the module in the admin service tree.** This matches the existing repository requirement that admin-owned service behavior lives in `modules/services/admin/`.
- **Promote the current implementation instead of keeping a forwarding layer.** The wrapper adds no reusable abstraction and obscures the real API surface.
- **Move the option namespace to `services.admin.termix`.** This aligns enablement, OIDC settings, and admin data-root mapping in one ownership domain.
- **Preserve runtime behavior.** Podman container names and supporting systemd units remain unchanged so dependent wiring such as `podman-termix.service` continues to work.

## Risks / Trade-offs

- **Namespace migration risk** → Update all known in-repo consumers from `services.termix` to `services.admin.termix` in the same change.
- **Accidental behavior drift** → Keep container definitions, tmpfiles rules, assertions, and port mappings unchanged while relocating them.
- **Future discoverability trade-off** → Termix becomes admin-scoped rather than generic, but that matches its actual usage and current architecture.
