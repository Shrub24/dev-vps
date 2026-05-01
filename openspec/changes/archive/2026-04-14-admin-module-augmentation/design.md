## Context

`applications.admin` currently wires Termix and its Tailscale Serve mapping, but the operator intent is to make the admin profile the single place for baseline operations tools. We need to add Cockpit, Webhook, Ntfy, Gatus (replacing Uptime Kuma), Vaultwarden, Filebrowser, Homepage Dashboard, and Beszel hub using nixpkgs-native services while preserving the project constraints: private-first networking, low bootstrap complexity, and reproducible host composition.

The change is cross-cutting within the admin capability because it touches application composition (`modules/applications/admin.nix`), host behavior, and operational verification.

## Goals / Non-Goals

**Goals:**
- Expand admin profile wiring to include Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Filebrowser, Homepage Dashboard, and Beszel hub with minimal viable config.
- Keep state locations predictable under `applications.admin.dataRoot` where service options support configurable storage.
- Preserve private/Tailscale-first posture by avoiding public-ingress assumptions in baseline wiring.
- Keep implementation host-extensible for future fleet growth.

**Non-Goals:**
- Adding public reverse proxy or internet exposure.
- Deep hardening/policy tuning beyond safe baseline service enablement.
- Replacing Termix or changing existing break-glass/Tailscale SSH contracts.

## Decisions

### Decision AM-1: Use nixpkgs-native service modules only
- **Chosen:** `services.cockpit`, `services.webhook`, `services.ntfy-sh`, `services.gatus`, `services.vaultwarden`, `services.filebrowser`, `services.homepage-dashboard`, and `services.beszel.hub`.
- **Why:** matches project complexity constraints and avoids container drift for core admin stack.
- **Alternative considered:** custom containers/systemd units per service. Rejected as unnecessary operational surface.

### Decision AM-2: Keep admin composition centralized in `applications.admin`
- **Chosen:** wire all new admin services from `modules/applications/admin.nix` rather than per-host ad hoc definitions.
- **Why:** preserves host-centric composition with reusable application profiles.
- **Alternative considered:** enabling services directly in host files. Rejected due to duplication and weaker contract consistency.

### Decision AM-3: Standardize data paths under `cfg.dataRoot` when supported
- **Chosen:** map configurable data/state directories into `${cfg.dataRoot}/<service>`.
- **Why:** keeps persistent state predictable and aligned with repository storage conventions.
- **Alternative considered:** leaving service defaults. Rejected where configurable because defaults are less explicit for fleet operations.

### Decision AM-4: Private exposure baseline first
- **Chosen:** no new public ingress defaults; service accessibility remains constrained to existing private networking model.
- **Why:** aligns with Tailscale-first requirement and minimizes attack surface during first-host maturation.
- **Alternative considered:** opening service ports publicly for convenience. Rejected on security and scope grounds.

### Decision AM-5: Defer cross-host journald synchronization
- **Chosen:** remove journald remote/upload sync from this stage and defer to a dedicated logging change.
- **Why:** current implementation shows intermittent receiver-side connection closures and is not required to deliver this stage’s admin baseline.
- **Alternative considered:** keep journald sync and continue debugging in-scope. Rejected to preserve stage focus and unblock completion.

## Risks / Trade-offs

- **[Risk] Service-specific option mismatches across nixpkgs modules** → **Mitigation:** validate with `nix flake check` and adjust to exact option names/types.
- **[Risk] More enabled services increase host resource footprint** → **Mitigation:** start with minimal config, avoid optional heavy features, and monitor service health.
- **[Risk] Accidental exposure from service defaults** → **Mitigation:** explicitly review listen/bind/firewall-related options and keep no-public-ingress baseline.
- **[Risk] Multi-host drift if only one host is verified** → **Mitigation:** keep wiring profile-centric and avoid provider-specific assumptions in admin module.

## Migration Plan

1. Update `modules/applications/admin.nix` to enable and minimally configure the expanded admin service set.
2. Add/adjust per-service state directory mappings under `${cfg.dataRoot}` where applicable.
3. Update or add capability delta spec assertions for the expanded admin-service contract.
4. Run `nix flake check` and relevant contract tests.
5. Deploy to target host via existing host-targeted workflow and verify service units.

Rollback:
- Revert the change and redeploy previous generation (`nixos-rebuild --rollback` or generation switch).
- Validate Tailscale and Termix baseline remains intact.

## Open Questions

- Should Cockpit machine management features be constrained further at baseline (e.g., package/plugin scope)?
- Should any of the newly added services receive dedicated Tailscale Serve mappings in this change, or remain internal-only initially?
- Do we need explicit contract tests per new service now, or in a follow-up hardening change?
- Which long-term cross-host logging architecture should replace deferred journald remote/upload (e.g., Loki/promtail/vector/syslog-ng)?
