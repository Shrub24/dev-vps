## 1. Tagr Service Module and Music Composition

- [x] 1.1 Add `modules/services/tagr.nix` with container runtime, `/srv/data/tagr` persistence, `/srv/media` mount wiring, and host port `3000` defaults
- [x] 1.2 Import and wire Tagr in `modules/applications/music.nix` as manual fallback service while preserving SoulSync/beets role boundaries
- [x] 1.3 Ensure service ordering, mount prerequisites, and tmpfiles ownership align with existing media module conventions

## 2. Host-Scoped Secrets and Templates

- [x] 2.1 Add Tagr secret keys and template wiring in `hosts/oci-melb-1/default.nix` for `AUTH_SECRET`, `AUTH_USER`, and `AUTH_PASSWORD`
- [x] 2.2 Update `hosts/oci-melb-1/secrets.template.yaml` with Tagr placeholder values for operator bootstrap
- [x] 2.3 Keep Tagr secret scope host-local and verify no `.sops.yaml` blast-radius expansion is needed

## 3. Edge Route and Admin Surface Integration

- [x] 3.1 Add `tagr` service entry to `policy/web-services.nix` with `tailscale-upstream`, `declarePublic = true`, Cloudflare Access required, and AOP required
- [x] 3.2 Add Tagr entry in `modules/services/admin/homepage/data.nix` using canonical route-derived href
- [x] 3.3 Update ingress/admin contract tests to include Tagr route and homepage presence expectations where applicable

## 4. Documentation and Validation

- [x] 4.1 Update `docs/architecture.md` to describe Tagr as manual metadata fallback within the music stack
- [x] 4.2 Run `just check` and targeted phase contract scripts; resolve regressions
- [x] 4.3 Validate `nix eval` for `do-admin-1` edge routes and `oci-melb-1` service options include Tagr wiring

## 5. Tagr Folder Scope Refinement

- [x] 5.1 Restrict Tagr runtime mounts and `MUSIC_FOLDERS` to `/srv/media/library` and `/srv/media/quarantine`
- [x] 5.2 Mask `.stversions` subdirectories from Tagr-visible library and quarantine paths
- [x] 5.3 Run scoped validation plus `openspec validate --strict` after the refinement

## 6. Syncthing Version Path Refinement

- [x] 6.1 Move Syncthing library and quarantine version archives to media-local paths outside the scanned trees
- [x] 6.2 Remove no-longer-needed Tagr `.stversions` masking workaround and keep Tagr scoped to library/quarantine only
- [x] 6.3 Run scoped validation plus `openspec validate --strict add-tagr-manual-fallback` after the version-path refinement

## 7. Tagr Permission Reconciliation

- [x] 7.1 Add a pre-start permission reconcile step so Tagr can write metadata and artwork under library and quarantine paths
- [x] 7.2 Validate Tagr runtime group/write wiring remains aligned with music-ingest/media ownership conventions
- [x] 7.3 Document safe cleanup steps for legacy in-tree `.stversions` folders after Syncthing path migration and rerun scoped validation

## 8. Source Permission Model Refinement

- [x] 8.1 Remove the Tagr-specific permission reconcile unit and keep Tagr aligned with existing container permission patterns
- [x] 8.2 Strengthen canonical library/quarantine tmpfiles ACL policy so new content inherits music-ingest write access at the source
- [x] 8.3 Run scoped validation and provide one-time manual repair guidance for pre-existing files that still lack the expected ACLs

## 9. Tagr Runtime Identity Alignment

- [x] 9.1 Align Tagr Podman runtime options with host ingest/media group IDs following the SoulSync permissions-hardening pattern
- [x] 9.2 Validate evaluated Tagr container runtime options include the expected user/group settings and keep ACL policy unchanged
- [x] 9.3 Provide updated deploy verification steps for confirming Tagr writes succeed after restart

## 10. SoulSync Disablement Cleanup

- [x] 10.1 Disable SoulSync in `modules/applications/music.nix` without removing the existing module or Tagr/manual fallback wiring
- [x] 10.2 Run scoped validation plus `openspec validate --strict add-tagr-manual-fallback` after the disablement change
- [x] 10.3 Archive the completed change once validation passes
