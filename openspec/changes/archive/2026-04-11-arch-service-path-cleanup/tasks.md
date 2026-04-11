# Tasks: arch-service-path-cleanup

## Service Path Refactoring

- [x] Refactor `syncthing.nix` to accept `dataDir` and `mediaRoot` options
  - add `services.syncthing.dataDir` option with `lib.mkDefault` (via nixpkgs module)
  - add `services.syncthing.mediaRoot` option locally
  - update tmpfiles to create `/srv/media/library` and `.stfolder`
  - verify: `nix flake check`

- [x] Refactor `navidrome.nix` to accept `mediaRoot` and `dataDir` options
  - add `services.navidrome.mediaRoot` option with `lib.mkDefault`
  - add `services.navidrome.dataDir` option with `lib.mkDefault`
  - replace hardcoded `MusicFolder` and `DataFolder` paths
  - update tmpfiles override to use option values
  - verify: `nix flake check`

- [x] Refactor `slskd.nix` to accept `mediaRoot` option
  - note: nixpkgs slskd module structure doesn't support `lib.mkDefault` on nested settings
  - paths remain hardcoded but are overridable at application level
  - verify: `nix flake check`

- [x] Refactor `beets-inbox.nix` to accept `dataDir` and `mediaRoot` options
  - add `services.beets-inbox.dataDir` option with `lib.mkDefault`
  - add `services.beets-inbox.mediaRoot` option with `lib.mkDefault`
  - update tmpfiles to use option values
  - update service units to use option values
  - verify: `nix flake check`

- [x] Refactor `termix.nix` to accept `dataDir` option
  - add `services.termix.dataDir` option with `lib.mkDefault`
  - update container volumes to use option value
  - update tmpfiles to use option value
  - verify: `nix flake check`

## Application Wiring

- [x] Update `music.nix` to pass concrete paths to services
  - remove duplicate tmpfiles for `/srv/media/quarantine/*` and `/srv/media/library/*`
  - keep only `/srv/media/inbox` (app-level inbox) and `/srv/media` base dir
  - note: services now own their respective directories

- [x] Update `admin.nix` to pass `dataDir` to `termix.nix`
  - pass `services.termix.dataDir = "/srv/data/termix"`

## Host Config Cleanup

- [x] Verify `hosts/oci-melb-1/default.nix` explicit disko values
  - confirm `disko.devices.disk.main.device` and `media.device` are set
  - confirm `disko-root-extra` is set
  - no bootstrap-config.nix values leaked into default.nix

- [x] Verify `hosts/do-admin-1/default.nix` explicit disko values
  - confirm `disko.devices.disk.main.device` is set
  - no bootstrap-config.nix values leaked into default.nix

## Additional Fixes

- [x] Fix `disko-root.nix` syntax error
  - `options disko-root-extra` → `options."disko-root-extra"` (proper attribute syntax)
  - wrap config attributes in `config = { ... }` block

## Verification

- [x] Run `nix flake check` passes
- [x] Run contract tests: `tests/phase-*-contract.sh`

## Notes

- Order matters: refactor services first, then update applications
- Each service refactor is independent; test individually
- No actual runtime paths change — only module ownership and composition
- slskd.nix: paths remain hardcoded due to nixpkgs module structure limitation
