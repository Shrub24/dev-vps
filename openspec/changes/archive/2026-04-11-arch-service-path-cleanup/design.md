## Context

`modules/services/` contains 7 service modules. Of these, 5 hardcode paths:

| Module | Hardcoded paths |
|---|---|
| `syncthing.nix` | `/srv/data/syncthing`, `/srv/media/library`, `/srv/media/quarantine` |
| `navidrome.nix` | `/srv/media`, `/srv/data/navidrome` |
| `slskd.nix` | `/srv/media/inbox/slskd`, `/srv/media/slskd/incomplete` |
| `beets-inbox.nix` | `/srv/data/beets`, `/srv/media/*` (8+ paths) |
| `termix.nix` | `/srv/data/termix/*` |

`modules/applications/music.nix` imports 4 service modules and also creates tmpfiles rules for paths it does not own — specifically `/srv/media/quarantine/*` and `/srv/media/library/.stfolder` (which `syncthing.nix` creates separately, creating duplicate directory entries for the same paths).

`hosts/*/default.nix` sets `disko-root-extra` inline rather than flowing it from `bootstrap-config.nix`.

The `bootstrap-config.nix` files exist but are only consumed by shell scripts, not the Nix module system.

## Goals / Non-Goals

**Goals:**
- Each service module accepts `mediaRoot`/`dataDir` options with sensible defaults
- Directory ownership is unambiguous: a service creates the directories it reads/writes
- Application modules (`music.nix`, `admin.nix`) do the path wiring, not the services
- Bootstrap device/size values flow from `bootstrap-config.nix` → host `default.nix` → storage modules
- No service module hardcodes a path that another module's runtime depends on

**Non-Goals:**
- No schema migration or database changes
- No changes to actual mount points or runtime behavior (paths remain `/srv/media`, `/srv/data`)
- No new NixOS module options beyond `mediaRoot`/`dataDir`-style path tuning
- OCI and DO keep separate disko layouts — the two-shape model is intentional

## Decisions

### 1. Option pattern: `lib.mkOption` with `lib.mkDefault`

Each service gets a top-level option (e.g. `services.syncthing.dataDir`) with a `lib.mkDefault` fallback matching current behavior. This is the standard NixOS pattern — options are always visible and overridable, but have safe defaults.

```
services.syncthing.dataDir = lib.mkDefault "/srv/data/syncthing";
```

Applications that import multiple services override these at composition time:

```nix
services.syncthing.dataDir = "/srv/data/syncthing";
services.beets-inbox.dataDir = "/srv/data/beets";
```

**Alternatives considered:**
- `config.disko.*` references: too tightly coupled to disko module
- Extra files / environment variables: adds runtime indirection

### 2. tmpfiles ownership: service creates dirs it uses

`music.nix` removes all `/srv/media/*` and `/srv/data/syncthing/*` tmpfiles rules. Each service creates the directories it needs:

- `syncthing.nix`: creates `/srv/data/syncthing`, `/srv/data/syncthing/config`, `/srv/media/library`, `/srv/media/library/.stfolder`
- `beets-inbox.nix`: creates `/srv/data/beets`, `/srv/media/quarantine`, `/srv/media/quarantine/untagged`, `/srv/media/quarantine/approved`
- `navidrome.nix`: creates `/srv/data/navidrome`
- `slskd.nix`: creates `/srv/media/inbox/slskd`, `/srv/media/slskd/incomplete` (only if dir does not exist — uses `z` type)
- `music.nix`: keeps only `/srv/media/inbox` (its own inbox, not a service-owned path)

**Alternatives considered:**
- Central `storage-assets.nix`: adds another module indirection for a simple tmpfiles rule
- `disko-root.nix` creates all dirs: mixes filesystem layout with service config

### 3. `bootstrap-config.nix` stays shell-only; host config is explicit

`bootstrap-config.nix` is read by `deploy.sh` and `resolve-host-config.sh` for bootstrap-time values. It is NOT imported into the Nix module system. Instead, the host's `default.nix` explicitly sets storage and provider options using values that match `bootstrap-config.nix`:

```nix
# hosts/oci-melb-1/default.nix
disko.devices.disk.main.device = "/dev/sda";
disko.devices.disk.media.device = "/dev/sdb";
disko-root-partition-size = "20G";  # matches bootstrap-config.nix
```

This avoids the circular problem of bootstrap-config being needed at evaluation time.

### 4. Two disko shapes are intentional

`disko-root.nix` (root + data + media disk) and `disko-single-disk.nix` (root only) encode fundamentally different partition layouts. They remain separate host-scoped modules. The only configurability added is `rootPartitionSize` via `disko-root-extra` (already added).

## Risks / Trade-offs

[Risk] Duplicated directory creation across modules → [Mitigation] Each directory has exactly one owner after refactor; grep for mountpoint strings in tmpfiles to verify.

[Risk] Changing tmpfiles order matters (parent must exist before child) → [Mitigation] NixOS tmpfiles processes `z` (create-or-update) before `d` (create) types, so child dirs can reference parents created by another module; verify with `systemd-tmpfiles --cat-config`.

[Risk] Circular import between `music.nix` and services → [Mitigation] Services do NOT import applications; music imports services; no cycle.

[Risk] `lib.mkDefault` on a path that another module also references → [Mitigation] Only one module sets each path option; applications override at import time.

## Migration Plan

1. Refactor services one at a time: syncthing → navidrome → slskd → beets-inbox → termix
2. For each service: add options, update tmpfiles, verify `nix flake check` passes
3. After all services refactored: remove duplicate tmpfiles from `music.nix`
4. Update host `default.nix` to pass explicit disko device/size values
5. Run all contract tests (`tests/phase-*-contract.sh`)
6. No rollback expected — paths are identical, only module ownership changes

## Open Questions

1. Should `termix.nix` also create `/srv/data/termix` or let `admin.nix` own that? **Decision: termix.nix creates its own data dir.**
2. Should `slskd.nix` own `/srv/media/inbox` (the parent dir)? **Decision: music.nix keeps `/srv/media/inbox` since it's an app-level inbox, not slskd-specific.**
3. Do we need a `mediaRoot` option on every service, or only on services that have more than one path? **Decision: each service gets the options it needs — no need to pass mediaRoot to a service that only uses dataDir.**
