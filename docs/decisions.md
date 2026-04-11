# Decisions

This document captures architecture and planning decisions agreed so far. It is intentionally high signal and should be updated as decisions change.

## Decision Register

## D-001: Repository mission changed from dev VPS to fleet infrastructure

Status: Accepted

Decision:

- this repository now targets modular multi-host NixOS infrastructure
- prior single-purpose `dev-vps` framing is legacy and scheduled for cleanup

Rationale:

- current goals are infrastructure reproducibility and service deployment across hosts
- old direction mixed personal environment and app-specific concerns that are now out of focus

## D-002: First host identity

Status: Accepted

Decision:

- first host is `oci-melb-1`

Rationale:

- establishes a concrete anchor for initial architecture and secrets policy

## D-003: Initial service scope

Status: Accepted

Decision:

- initial active services are `navidrome`, `syncthing`, and `tailscale`
- `k3s`, `keda`, and cloud-worker details are explicitly deferred

Rationale:

- native service baseline provides faster validation with lower complexity

## D-004: Secrets model uses blast-radius scoping

Status: Accepted

Decision:

- maintain split between:
  - `secrets/common.yaml`
  - `hosts/<hostname>/secrets.yaml`
- define recipients in `.sops.yaml` with explicit path-scoped rules

Rationale:

- minimizes unnecessary decryption access across hosts
- aligns with future fleet growth and service mobility decisions

## D-005: Tailscale enrollment tokens are host-scoped

Status: Accepted

Decision:

- prefer per-host enrollment secrets over one reusable shared key

Rationale:

- better auditability and smaller blast radius on token exposure

## D-006: Syncthing operating mode starts bidirectional with safety controls

Status: Accepted

Decision:

- start with bidirectional sync
- include versioning/conflict protections in configuration posture

Rationale:

- matches current peer-style workflow
- retains flexibility before authority centralization with later `rclone` direction

## D-007: Storage model starts with one persistent mount

Status: Accepted

Decision:

- use one data mount for now and organize service paths under it
- avoid duplicate datasets/staging initially

Rationale:

- simplest operational model
- avoids unnecessary storage overhead during early stages

## D-008: Media path is direct for now

Status: Accepted

Decision:

- Navidrome reads directly from Syncthing-managed path initially

Rationale:

- reduces complexity and storage duplication
- delayed ingest/pipeline split can be introduced when processing needs are concrete

## D-009: Deployment tooling sequence

Status: Accepted

Decision:

- bootstrap with `nixos-anywhere`
- adopt fleet deployment tooling after first host stabilization

Rationale:

- keeps first-host bring-up simpler
- avoids early operational overhead while preserving future compatibility

## D-010: Secrets bootstrap default is two-step

Status: Accepted

Decision:

- default to two-step bootstrap for secrets on new host bring-up

Rationale:

- lower risk in early bootstrap
- less pre-install handling of sensitive identity material

## D-011: Pre-generated host identity is allowed but treated as advanced

Status: Accepted (conditional)

Decision:

- pre-generated host key material can be used when first-boot secret decryption is required
- this is not the baseline path

Rationale:

- valid approach with deterministic first-boot identity
- higher operational sharpness and identity-coupling complexity than two-step bootstrap

## D-012: Cleanup posture

Status: Accepted

Decision:

- perform aggressive cleanup of legacy `dev-vps` direction on migration branch

Rationale:

- reduces confusion and maintenance burden
- reinforces clear repository mission

## D-013: Access exposure policy

Status: Accepted

Decision:

- keep services private and Tailscale-only for now

Rationale:

- minimizes attack surface during architecture transition

## D-014: Full repository cutover now (no long-lived bridge)

Status: Accepted

Decision:

- use `nixosConfigurations.oci-melb-1` as the active flake output now
- keep host identity in `hosts/oci-melb-1/default.nix`
- remove legacy `nixosConfigurations.dev-vps` and associated personal-tooling outputs from active wiring

Rationale:

- avoids dual-mission drift and broken references in active workflows
- keeps operator and CI surfaces aligned to a single canonical host target

## D-015: Reusable module boundaries are explicit in active paths

Status: Accepted

Decision:

- baseline shared policy lives in `modules/core/base.nix`
- profile composition lives in `modules/profiles/base-server.nix`
- service boundary for private access starts in `modules/services/tailscale.nix`

Rationale:

- separates host identity from reusable logic for future host growth
- keeps provider-specific concerns out of reusable modules

## D-016: Documentation authority and derivation contract

Status: Accepted

Decision:

- `docs/` is canonical for architecture, decisions, and migration direction
- `README.md` remains orientation-only with links to canonical docs
- `CLAUDE.md` is a derived mirror and must not conflict with canonical `docs/`

Rationale:

- prevents conflicting migration narratives during aggressive cutover
- keeps implementation and operator guidance synchronized

## D-017: Add a narrow applications composition layer for current host systems

Status: Accepted

Decision:

- add `modules/applications/music.nix` to compose Syncthing, Navidrome, and slskd for `oci-melb-1`
- add `modules/applications/admin.nix` to compose private admin access through Tailscale plus Termix
- keep low-level implementation in `modules/services/*.nix` and avoid broad repository reorganization

Rationale:

- introduces an explicit logical application boundary without disrupting existing host behavior
- preserves service-level reuse while making host composition easier to reason about

## D-018: Termix runs as a Tailscale-only admin application on oci-melb-1

Status: Accepted

Decision:

- implement Termix with a dedicated low-level module `modules/services/termix.nix` using Podman OCI containers (`termix` + `guacd`)
- persist Termix state under `/srv/data/termix`
- keep public exposure unchanged (no new firewall openings)

Rationale:

- adds private remote admin capability while keeping the project's Tailscale-first posture intact
- keeps runtime/container specifics isolated from host composition and canonical docs

## D-019: Music app owns generic ingest boundary and slskd is confined to service subtree

Status: Accepted

Decision:

- `modules/applications/music.nix` owns `/srv/media/inbox` as a generic ingest boundary through `music-ingest`
- `slskd` is confined to `/srv/media/inbox/slskd` for completed downloads and `/srv/media/slskd/incomplete` for partial data
- Syncthing and Navidrome remain anchored on `/srv/data/media` as the authoritative library path

Rationale:

- keeps cross-service ingest ownership at the application layer instead of expanding core user/module scope
- allows future ingest producers to share one boundary while preventing slskd path sprawl
- preserves the direct authoritative media flow without reintroducing duplicate staging ownership

## D-020: OCI media authority moves to dedicated `/srv/media` mount

Status: Accepted

Decision:

- `hosts/oci-melb-1/bootstrap-config.nix` declares a dedicated `mediaDisk = "/dev/sdb"`
- OCI provider defaults bind `bootstrapConfig.mediaDisk` into `disko.devices.disk.media.device`
- `modules/storage/disko-root.nix` mounts the media filesystem at `/srv/media`
- Syncthing, Navidrome, and slskd shared-library references move from `/srv/data/media` to `/srv/media`
- `/srv/data` remains responsible for service-state paths (`/srv/data/syncthing/config`, `/srv/data/navidrome`)
- `/srv/media` now owns the media library plus ingest/download paths (`/srv/media`, `/srv/media/inbox`, `/srv/media/slskd`)
- introduce `music-library` group so `/srv/media` is writable by Syncthing and the `dev` operator account without changing service ownership to a human user

Rationale:

- separates authoritative media storage from service-state and ingest data to reduce path-coupling drift
- keeps the existing app-owned ingest boundary and state layout stable while introducing explicit media disk contract checks
- aligns phase-03/phase-04 contracts and canonical docs with the storage split so regressions fail quickly

## D-021: Beets remains inbox-only singleton worker with no promotion behavior

Status: Superseded by D-022

Decision:

- add an inbox-only Beets worker for `oci-melb-1` that runs singleton imports against `/srv/media/inbox/slskd`
- trigger routine runs automatically through `systemd.path` file events
- keep all Beets runtime state and reports under `/srv/data/beets`
- enforce no promotion behavior: no copy/move/link/hardlink flow out of inbox

Rationale:

- satisfies MEDI-02, MEDI-03, and MEDI-04 without changing established `/srv/media` authority
- keeps ingestion automation conservative so unmatched/weak candidates remain in place for manual follow-up
- avoids accidental scope creep into a future authority/promotion pipeline before that phase is explicitly planned

## D-022: Beets runs all-inbox native auto-promotion into /srv/media/library

Status: Accepted

Decision:

- evolve the Beets worker to scan `/srv/media/inbox` broadly using native album import semantics
- auto-promote successful files into `/srv/media/library/<top-level>/<release>/<original filename>`
- keep filename preservation as a strict contract during move/promotion
- keep Beets runtime state and built-in import logs under `/srv/data/beets`
- preserve broad playback visibility by keeping Navidrome rooted on `/srv/media`

Rationale:

- advances MEDI-01 with a native systemd and Beets-based promotion path (`singletons: no`, `group_albums: yes`) without introducing app-based review complexity
- keeps hard failures visible and playable from inbox while successful files become canonical library entries
- maintains the `/srv/media` authority model and service-state/report separation under `/srv/data`

## D-023: Beets worker is transfer-safe, serialized, and performs post-run demotion sweep

Status: Accepted

Decision:

- trigger Beets worker from inbox modification events under `/srv/media/inbox`
- require transfer-lock behavior: if any `.tmp` file exists under inbox, worker exits without invoking Beets
- apply a fixed settle/debounce delay after transfer lock clears before import starts
- rely on native systemd single-instance service behavior so overlapping path/timer triggers do not create concurrent workers
- keep Beets headless album import execution (`-q`, `singletons: no`, `group_albums: yes`) and preserve original filenames via native Beets path templating
- after Beets completes, sweep any remaining inbox audio into `/srv/media/quarantine/untagged` to prevent recursive loops and restore zero-state inbox for eligible files

Rationale:

- aligns implementation with operational acceptance criteria for robust mobile-first ingest automation
- avoids partial-transfer races and repeated loop triggers caused by residual inbox files
- preserves playlist safety by keeping downloaded basenames unchanged during both promotion and demotion

## D-024: Quarantine uses music-ingest ownership with explicit media read-only ACLs and dedicated approved promotion config

Status: Accepted

Decision:

- Syncthing sync scope includes both `/srv/media/library` and `/srv/media/quarantine`
- quarantine paths (`/srv/media/quarantine`, `untagged`, `approved`) are owned by `music-ingest`
- apply ACLs so `media` has explicit read-only (`r-x`/`r-X`) access to quarantine paths while `syncthing` retains explicit write access for sync operations
- codify Syncthing marker files (`.stfolder`) at `/srv/media/library/.stfolder` and `/srv/media/quarantine/.stfolder` with `syncthing:syncthing` ownership via tmpfiles
- add a secondary Beets runner that targets `/srv/media/quarantine/approved` for manual re-attempt promotions with a dedicated approved-flow config
- keep Navidrome rooted on `/srv/media` so quarantine visibility remains explicit alongside promoted library content
- remove Navidrome playlist injection hacks and rely on media-root scanning for visibility

Rationale:

- preserves a permission-safe, reviewable quarantine flow without introducing public exposure or ad-hoc scripts
- keeps approved reprocessing native to systemd + Beets while avoiding recursive demotion behavior in the approved lane
- aligns quarantine ownership with ingest boundaries while keeping media-library review access read-only and Syncthing write-capable where needed

## D-025: Second host `do-admin-1` is added as a DigitalOcean x86_64 admin node

Status: Accepted

Decision:

- add `nixosConfigurations.do-admin-1` with `x86_64-linux`
- compose the host in `hosts/do-admin-1/default.nix` with shared `dev` user model
- isolate provider defaults in `modules/providers/digitalocean/default.nix`
- use `modules/storage/disko-single-disk.nix` for single-disk DO layout

Rationale:

- validates multi-provider, mixed-architecture fleet shape without perturbing `oci-melb-1`
- keeps provider and storage concerns modular instead of coupling to OCI bootstrap metadata

## D-026: Host age recipient bootstrap defaults to live SSH host key derivation

Status: Accepted

Decision:

- default bootstrap workflow derives host age recipient by fetching live SSH ed25519 host key (`host-generic` pattern)
- keep advanced injected-key workflow available for cases where live retrieval is not possible
- enforce host-scoped `.sops.yaml` rules per host (`hosts/<host>/secrets.yaml`)

Rationale:

- reduces manual key handling during day-0 bring-up while preserving scoped blast radius
- keeps a deterministic fallback for restricted network/bootstrap scenarios

## D-027: deploy-rs is the primary deployment workflow for both active hosts

Status: Accepted

Decision:

- add `deploy-rs` as a flake input and publish `deploy.nodes` for `oci-melb-1` and `do-admin-1`
- define host deploy metadata in `lib/deploy/hosts.nix` and reusable wiring in `lib/deploy/default.nix`
- set each node to `sshUser = "dev"`, host hostname, and `profiles.system.path` from the matching `nixosConfigurations.<host>`
- wire `deploy-rs` deployment checks into `flake checks` for both `aarch64-linux` and `x86_64-linux`
- make `just deploy`, `just deploy-activate`, and `just deploy-check` the primary operator workflow

Rationale:

- keeps deployment behavior host-centric and extensible as more nodes are added
- removes ad-hoc per-command deployment drift while preserving bootstrap/secrets flows
- ensures deployment schema validation is part of normal flake checks
>>>>>>> 12bdde3 (feat: deploy-rs deployment and digitalocean host bootstrap)

## Open Questions (Intentional)

These are known but intentionally unresolved until implementation and operational learning justify final decisions.

- when to introduce service-scoped secret files for movable workloads
- when and how to introduce `rclone`/VFS into media flow
- hook/event framework for future processing pipeline
- backup policy timing once host authority increases
- fleet tool choice and operating model once host count grows
