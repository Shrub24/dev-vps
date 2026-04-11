# Spec: Media Services

## Capability ID

`media-services`

## Summary

The repository provides declarative media service composition for music library management, including Syncthing for bidirectional sync with versioning safeguards, Navidrome for streaming, slskd for Soulseek downloads, and Beets for automated tagging and promotion. Services are composed via `modules/applications/music.nix` with explicit data flow contracts, group-based permissions, and mount-aware dependency ordering.

## Behaviors

### Service Composition

- **MS-1**: The `modules/applications/music.nix` module shall import and configure Syncthing, Navidrome, slskd, and Beets-inbox as an integrated media stack.
- **MS-2**: The composition shall define `music-ingest` and `media` Unix groups for path ownership and access control.
- **MS-3**: The `dev` user shall belong to `beets`, `music-ingest`, and `media` groups to permit manual intervention and log inspection.

### Storage Paths and Permissions

- **MS-4**: The `/srv/media` mount shall be the authoritative media root, owned by `root:root` with 0755 permissions.
- **MS-5**: The `/srv/media/inbox` directory shall be owned by `root:music-ingest` with 2775 setgid sticky-bit for group-writable ingest.
- **MS-6**: The `/srv/media/library` directory shall be owned by `root:media` with 2775 setgid sticky-bit and Syncthing ACLs (`user:syncthing:rwx`).
- **MS-7**: The `/srv/media/quarantine` directory shall be owned by `root:music-ingest` with 2775 setgid sticky-bit, ACLs for Syncthing, and read‑only ACLs for the `media` group.
- **MS-8**: All media directories shall be created and permission‑reconciled via `systemd.tmpfiles.rules` declared in `music.nix`.

### Syncthing Synchronization

- **MS-9**: Syncthing shall operate with `openDefaultPorts = false`, relying on Tailscale for peer connectivity.
- **MS-10**: Syncthing shall define a `media` folder at `/srv/media/library` with `type = "sendreceive"` and trashcan versioning (`cleanoutDays = "30"`, `cleanupIntervalS = "86400"`).
- **MS-11**: Syncthing shall define a `quarantine` folder at `/srv/media/quarantine` with the same versioning safeguards and explicit device targeting.
- **MS-12**: Syncthing’s data and config directories shall be rooted under `/srv/data/syncthing`.

### Navidrome Streaming

- **MS-13**: Navidrome shall be configured with `MusicFolder = "/srv/media"`, scanning every 15 minutes, and shall **not** manage `/srv/media` via its own tmpfiles rules.
- **MS-14**: Navidrome shall depend on `syncthing.service` (via `systemd.service` `wants`/`after`) to ensure the library is synchronized before scanning.
- **MS-15**: Navidrome shall have `openFirewall = false`, serving only over Tailscale private networking.

### Soulseek Integration (slskd)

- **MS-16**: slskd shall be configured with downloads directory `/srv/media/inbox/slskd` and incomplete directory `/srv/media/slskd/incomplete`.
- **MS-17**: slskd shall share the entire `/srv/media` tree as a Soulseek share.
- **MS-18**: slskd shall depend on `syncthing.service` to ensure media paths are available.

### Beets Integration

- **MS-19**: Beets shall be integrated as a singleton tagging worker with dedicated system user `beets`, home `/srv/data/beets`, and membership in `music-ingest` and `media` groups.
- **MS-20**: Beets shall process files from `/srv/media/inbox` and promote successfully tagged tracks to `/srv/media/library`, preserving original filenames.
- **MS-21**: Beets shall write fallback and hard‑failure reports under `/srv/data/beets` for operator review.
- **MS-22**: Beets automation details (systemd path watchers, timers, transfer‑safety) are specified in the separate `beets-automation` capability.

### Data Flow Contract

- **MS-23**: Syncthing shall be the authoritative sync source for `/srv/media/library` and `/srv/media/quarantine`.
- **MS-24**: Navidrome shall read directly from `/srv/media` (including library, inbox, and quarantine) but must **not** be restricted to `/srv/media/library` only.
- **MS-25**: Ingest sources (slskd, manual drops) shall place files under `/srv/media/inbox` or its subdirectories.
- **MS-26**: Beets shall move successfully processed files from `/srv/media/inbox` to `/srv/media/library`, and from `/srv/media/quarantine/approved` to `/srv/media/library`.
- **MS-27**: No duplicate staging paths shall exist; Navidrome reads the same authoritative paths managed by Syncthing.

### Operational Integrity

- **MS-28**: All service units shall declare `RequiresMountsFor` on `/srv/data` and `/srv/media` mounts.
- **MS-29**: Service start ordering shall enforce that Syncthing is ready before Navidrome or slskd begin.
- **MS-30**: Permission reconciliation shall run after Beets promotions to ensure ACLs and group ownership remain aligned with declared tmpfiles rules.

## Constraints

- Media services assume a dedicated `/srv/media` mount with stable device identifiers.
- All services operate within Tailscale‑only networking; no public firewall ports are opened.
- Syncthing versioning safeguards are mandatory, not optional.
- Beets automation is currently manual‑trigger (systemd path/timer disabled) pending transfer‑safety completion (MEDI‑05, MEDI‑06).

## Verification

- `tests/phase-04-syncthing-contract.sh` validates Syncthing folder definitions and versioning parameters.
- `tests/phase-04-service-flow-contract.sh` validates Navidrome root guard and no‑duplicate‑staging rule.
- `tests/phase-04.2-beets-promotion-contract.sh` validates promotion behavior and reporting outputs.
- `just verify-phase-04` runs the full media‑service contract suite.