## Context

The repository already defines SoulSync as primary ingest and beets as manual rescue fallback, but there is no dedicated browser-first metadata editor for targeted repairs (bad album art, unknown artist/album, malformed tags) after imports land in canonical media paths. Tagr fills that gap as operator tooling, not a new primary ingest path.

This is a cross-cutting change touching service composition (`music.nix`), host-scoped secrets on `oci-melb-1`, canonical edge route policy on `do-admin-1`, and admin homepage wiring. Existing strict route/policy contracts and private-upstream posture must remain intact.

## Goals / Non-Goals

**Goals:**
- Add Tagr as manual fallback metadata/cover editor on `oci-melb-1`.
- Keep canonical media paths and SoulSync/beets role boundaries unchanged.
- Expose Tagr via existing canonical edge policy model (`tailscale-upstream`, Access-gated, AOP).
- Keep Tagr credentials host-scoped via SOPS templates.

**Non-Goals:**
- Do not replace SoulSync as primary ingest.
- Do not introduce Tagr as unattended automation.
- Do not add public direct-origin exposure on `oci-melb-1`.
- Do not broaden secret scope beyond `hosts/oci-melb-1/secrets.yaml`.

## Decisions

- **TG-1 (Deployment model):** Run Tagr as a pinned upstream container (`ghcr.io/suitux/tagr:latest`) via `virtualisation.oci-containers` in a new `modules/services/tagr.nix`.
  - **Rationale:** Upstream is container-first and already documents required runtime env/volume model.
  - **Alternative considered:** Nix-native Node build/runtime packaging; rejected for this wave to reduce integration effort.

- **TG-2 (Path scope):** Mount canonical media root for read/write metadata updates and keep Tagr state in `/srv/data/tagr`.
  - **Rationale:** Repairs must target canonical files in place, while app state remains under service-state mount conventions.
  - **Alternative considered:** Restrict to quarantine-only paths; rejected because user requested fallback for already-imported metadata/covers too.

- **TG-3 (Auth wiring):** Use host-scoped template-rendered env file for `AUTH_SECRET`, `AUTH_USER`, and `AUTH_PASSWORD`.
  - **Rationale:** Matches existing SOPS template patterns and preserves blast-radius boundaries.
  - **Alternative considered:** Generate random credentials at runtime; rejected due to operational reproducibility concerns.

- **TG-4 (Ingress posture):** Add `tagr` in canonical `policy/web-services.nix` with `tailscale-upstream`, `declarePublic = true`, Access required, and AOP required.
  - **Rationale:** Consistent with existing public admin/app route controls and edge rendering path.
  - **Alternative considered:** Tailscale-only route; rejected because existing operator workflows use edge-gated web access.

- **TG-5 (Operator visibility):** Add Tagr shortcut entry to Homepage `Glance` section without introducing machine-auth widget requirements.
  - **Rationale:** Keeps fallback discoverable while avoiding unsupported homepage widget auth contracts.
  - **Alternative considered:** Add authenticated widget integration; rejected because homepage currently has no Tagr widget contract.

## Risks / Trade-offs

- **[R1] Accidental metadata edits in canonical library** -> **Mitigation:** Position Tagr as manual fallback only; keep SoulSync/beets defaults unchanged and document operator intent.
- **[R2] Upstream `latest` image drift** -> **Mitigation:** Keep module image option overridable/pinnable in host config for quick rollback control.
- **[R3] Missing Tagr secrets breaks startup** -> **Mitigation:** Gate required env-file with declarative assertions and host template checks.
- **[R4] Route policy regressions** -> **Mitigation:** Add/adjust route contract checks and preserve existing exposure/AOP invariants.

## Migration Plan

1. Add `modules/services/tagr.nix` with container config, tmpfiles, mounts, and service ordering.
2. Import Tagr module in `modules/applications/music.nix` and wire defaults (`/srv/data/tagr`, `/srv/media`, port `3000`).
3. Add host-scoped Tagr secret keys/templates in `hosts/oci-melb-1/default.nix` and template placeholders in `hosts/oci-melb-1/secrets.template.yaml`.
4. Add canonical `tagr` route in `policy/web-services.nix` targeting `oci-melb-1.tail0fe19b.ts.net:3000` with Access + AOP requirements.
5. Add Tagr link entry in `modules/services/admin/homepage/data.nix`.
6. Update docs/spec deltas and run repo contract checks.

Rollback strategy:
- Remove Tagr route and module wiring, preserving media/data directories.
- Keep secrets keys present (unused) or remove in a follow-up cleanup commit.

## Open Questions

- Should Tagr route keep Cloudflare Access required by default (recommended) or follow Navidrome-style exception posture?
- Should initial Tagr image remain `latest` (upstream recommendation) or pinned by digest immediately in this change?
