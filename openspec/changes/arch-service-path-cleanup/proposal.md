## Why

Service modules under `modules/services/` hardcode `/srv/media` and `/srv/data` paths throughout, making them non-reusable and tightly coupled to a single host layout. Additionally, `modules/applications/music.nix` creates directory trees (`/srv/media/quarantine/*`) via tmpfiles that are owned by `beets-inbox.nix`, creating duplicate ownership. Bootstrap values also leak into `default.nix` instead of flowing from `bootstrap-config.nix` through the module system. This must be cleaned up before adding a third host or service.

## What Changes

- **Services accept path options**: `syncthing.nix`, `navidrome.nix`, `slskd.nix`, `beets-inbox.nix` each gain `mediaRoot` and/or `dataRoot` options; hardcoded paths are replaced with option references.
- **Duplicate tmpfiles removed**: `music.nix` no longer creates `/srv/media/quarantine/*`, `/srv/media/library/.stfolder` — those are owned by the services that need them.
- **Applications do the wiring**: `music.nix` passes concrete paths (`/srv/media`, `/srv/data`) to each service module it imports.
- **Bootstrap values stay in host config**: `bootstrap-config.nix` remains the single source of truth for device paths and root size; host `default.nix` passes them explicitly to storage/provider modules.
- **Termix path option added**: `termix.nix` accepts a `dataDir` option; `admin.nix` passes `/srv/data/termix`.
- **Disko modules stay host-scoped**: two shapes remain (`disko-root.nix` for OCI, `disko-single-disk.nix` for DO); partition sizes are configurable via host config.

## Capabilities

### New Capabilities
- `service-path-config`: Each service module (`syncthing`, `navidrome`, `slskd`, `beets-inbox`, `termix`) exposes options for its data and media paths. Applications that import multiple services pass concrete values at composition time.
- `dir-ownership`: Each service module owns the tmpfiles rules for directories it directly uses. Shared top-level directories (`/srv/media`, `/srv/data`) are not created by applications.
- `host-storage-config`: Host `default.nix` passes `bootstrapDisk`, `mediaDisk`, and `rootPartitionSize` from `bootstrap-config.nix` to storage/provider modules. No bootstrap values are set inline in `default.nix`.

### Modified Capabilities
- *(none — no existing spec-level requirements change)*

## Impact

**Files modified**: `modules/services/syncthing.nix`, `modules/services/navidrome.nix`, `modules/services/slskd.nix`, `modules/services/beets-inbox.nix`, `modules/services/termix.nix`, `modules/applications/music.nix`, `modules/applications/admin.nix`, `hosts/oci-melb-1/default.nix`, `hosts/do-admin-1/default.nix`, `modules/storage/disko-root.nix`, `modules/storage/disko-single-disk.nix`.

**No breaking changes to running services**: refactor is purely internal — paths remain `/srv/media` and `/srv/data` for OCI and DO hosts; only the module ownership and composition model changes.
