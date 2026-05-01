## Why

The first pass removed some hardcoding but missed the intended modular contract:

- `syncthing.nix` is still effectively app-specific (fixed folders/devices), rather than a reusable generic service module.
- Directory ownership boundaries are still partially ambiguous when services and applications share path concerns.
- Some runtime scripts still hardcode `/srv/*`, reducing portability when top-level dirs are injected.

We need a second pass so modules remain truly drop-in reusable while preserving current runtime layout.

## What Changes

- **Make Syncthing generic**: `modules/services/syncthing.nix` exposes reusable options (`dataDir`, `configDir`, `folderTargets`) and no longer hardcodes app-specific folder/device definitions.
- **Application owns composition**: `modules/applications/music.nix` defines concrete Syncthing devices/folders and path roots, then passes those into services.
- **Enforce ownership boundaries**:
  - app module owns shared top-level dirs (e.g. media root/inbox)
  - service modules own service-specific subdirs and ACLs
- **Keep Beets quarantine ownership in service**: `beets-inbox.nix` owns quarantine subtree (`quarantine`, `untagged`, `approved`) and media-read ACLs.
- **Parameterize runner/runtime paths**: beets runner and permission reconcile logic use module-injected paths, not fixed `/srv/*` literals.
- **Update tests minimally**: contract tests validate the new modular wiring without rewriting the whole test strategy.

## Capabilities

### New Capabilities
- `syncthing-generic-targets`: Syncthing supports arbitrary folder targets passed from the application layer (`folderTargets`) with optional marker/dir management behavior.
- `service-path-config`: Services consume injected top-level roots and derive self-owned subpaths locally.
- `dir-ownership`: shared top-level dirs are app-owned; service-specific trees are service-owned with explicit ACLs where collaboration is required.

### Modified Capabilities
- `media-services` (incremental change spec added in this change): clarify modular ownership and generic Syncthing composition contract.

## Impact

**Files modified**: `openspec/changes/arch-service-path-cleanup/{proposal.md,design.md,tasks.md}`, `openspec/changes/arch-service-path-cleanup/specs/media-services/spec.md`, `modules/services/{syncthing.nix,slskd.nix,beets-inbox.nix}`, `modules/applications/music.nix`, `scripts/beets-inbox-runner.sh`, and minimally affected phase-04 contract tests.

**Runtime behavior**: target paths remain `/srv/media` and `/srv/data` in current hosts, but module composition becomes generic and reusable.
