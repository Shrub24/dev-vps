## Context

The recent admin service split correctly moved substantial service-owned behavior into `modules/services/admin/`, but a few files still only proxy settings between namespaces or split small amounts of portable composition glue across multiple files. The main remaining inconsistency is Pocket ID, where admin composition still routes through `services.shrublab-pocket-id` even though the service is treated as admin-owned.

## Goals / Non-Goals

**Goals:**
- Make Pocket ID canonical under `services.admin.pocket-id`
- Keep portable admin composition host-agnostic by consolidating thin composition fragments into `modules/applications/admin/default.nix`
- Remove obsolete wrapper files/imports while preserving current behavior

**Non-Goals:**
- Rework larger admin service modules such as Homepage, Gatus, Cockpit, or Quantum
- Change admin route policy, OIDC secret sources, or runtime exposure behavior
- Flatten every small admin service module in this change

## Decisions

### D1. Canonical admin-owned Pocket ID lives in `modules/services/admin/pocket-id.nix`
Pocket ID is admin-owned in this repository, so its canonical module should live under `modules/services/admin/` rather than behind a generic wrapper. The admin module will expose `services.admin.pocket-id.{enable,dataDir,appUrl}` and directly configure upstream `services.pocket-id` runtime settings.

**Alternative considered:** keep `services.shrublab-pocket-id` as canonical and retain the admin wrapper. Rejected because it preserves namespace indirection without a real reuse boundary.

### D2. Portable admin composition should absorb very small split files
`modules/applications/admin/access.nix` and `modules/applications/admin/identity.nix` contain small, tightly coupled admin composition logic. Moving that logic into `modules/applications/admin/default.nix` keeps the admin composition portable without pushing it into any host-local file.

**Alternative considered:** keep separate files for conceptual grouping. Rejected because the current files are too small to justify the extra imports and mental indirection.

### D3. Preserve service-level admin modules for actual service ownership
This cleanup does not collapse substantive admin service modules such as Termix, Quantum, Cockpit, Homepage, or Gatus. The target is only wrapper-like or tiny composition-only splits.

## Risks / Trade-offs

- **[Risk] Namespace migration could miss a remaining `services.shrublab-pocket-id` consumer** → **Mitigation:** search all Nix files and update all references in this change.
- **[Risk] Folding access/identity glue into one file reduces conceptual separation** → **Mitigation:** keep the merged sections clearly grouped with local bindings and comments if needed.
- **[Risk] Behavior drift in OIDC or Tailscale serve wiring** → **Mitigation:** validate evaluated config values and systemd/container outputs after the refactor.

## Migration Plan

1. Add the change artifacts and task list.
2. Move Pocket ID options/runtime wiring to canonical `services.admin.pocket-id`.
3. Merge access and identity composition into `modules/applications/admin/default.nix`.
4. Delete obsolete wrapper/split files and remove their imports.
5. Validate targeted Nix evals and run strict OpenSpec validation.

Rollback is straightforward: restore the deleted thin wrapper files and previous imports if any regression appears.

## Open Questions

- None for this cleanup scope.
