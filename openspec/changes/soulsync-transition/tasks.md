## 1. SoulSync Service and Host Wiring

- [x] 1.1 Add `modules/services/soulsync.nix` with pinned upstream image via `virtualisation.oci-containers`, persistent state under `/srv/data/soulsync`, and mounts for `/srv/media/inbox/slskd`, `/srv/media/library`, and `/srv/media/quarantine/approved`
- [x] 1.2 Wire SoulSync into `modules/applications/music.nix` as the primary ingest service and remove `beets-inbox` from default automated composition
- [x] 1.3 Add host-scoped SoulSync secrets/templates in `hosts/oci-melb-1/default.nix` (required + optional providers) with optional-by-secret enablement behavior

## 2. Media Path and Fallback Flow Alignment

- [x] 2.1 Preserve canonical path roles for `inbox/slskd`, `library`, `quarantine/untagged`, and `quarantine/approved` in module wiring and runtime defaults
- [x] 2.2 Keep beets installed as fallback rescue tooling while ensuring beets is no longer the primary automated ingest owner
- [x] 2.3 Configure SoulSync defaults for conservative rollout: track-first partial import bias, Discogs-first metadata preference where available, and no broad pre-existing-library mutation jobs

## 3. Navidrome and Syncthing Contract Adjustments

- [x] 3.1 Update Navidrome composition so media scope includes `library + quarantine` and excludes `inbox`
- [x] 3.2 Confirm Syncthing continues to manage/sync `library` and `quarantine` without ingest-backend coupling regressions

## 4. Public Gated Route Integration

- [x] 4.1 Add `soulsync` service entry to canonical `policy/web-services.nix` with `exposureMode = "tailscale-upstream"`, `declarePublic = true`, `access.requireCloudflareAccess = true`, and `cloudflare.authenticatedOriginPulls = true`
- [x] 4.2 Verify `hosts/do-admin-1/default.nix` route resolution publishes SoulSync route via existing edge-ingress mapping without ad-hoc route wiring
- [x] 4.3 Implement best-effort SoulSync playback suppression/hiding for public UI where low-risk and supported; document residual behavior if complete suppression is unavailable

## 5. Validation and Documentation

- [x] 5.1 Run validation checks (`nix flake check` and relevant host evaluations) and resolve option/type regressions
- [ ] 5.2 Smoke test core flows: trusted ingest to library, unresolved to `quarantine/untagged`, rescue handoff through `quarantine/approved`, and SoulSync promotion path
- [ ] 5.3 Smoke test public `soulsync` route behavior (Access gate, AOP compatibility, mobile UI usability) and confirm no direct-origin exposure on `oci-melb-1`
- [x] 5.4 Update docs/decisions to reflect SoulSync-primary ingest, beets fallback posture, Navidrome scope change, and deferred future automated beets fallback policy
