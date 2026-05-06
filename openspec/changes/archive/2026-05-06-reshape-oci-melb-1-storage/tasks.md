## 1. Canonical storage shape

- [x] 1.1 Confirm `oci-melb-1` host wiring and `disko-single-disk` options match the recovered single-disk partition and mount layout.
- [x] 1.2 Validate rendered filesystem outputs for `/`, `/boot`, `/nix`, `/srv/data`, and `/srv/media` against the intended OCI layout.

## 2. Media/tmpfiles cleanup

- [x] 2.1 Identify duplicate tmpfiles directory-creation ownership rules for shared media paths.
- [x] 2.2 Refactor the relevant modules so shared media directories are created once declaratively while ACL and marker-file behavior still renders correctly.
- [x] 2.3 Verify Syncthing/music-related paths (`/srv/media/library`, `/srv/media/quarantine`, `/srv/media/inbox`, markers, ACL hooks) still evaluate and create correctly.

## 3. Recovery documentation and validation

- [x] 3.1 Document the validated rescue-instance recovery workflow for storage/mount failures.
- [x] 3.2 Run repo validation (`nix flake check` with appropriate source mode and targeted eval checks) and fix any issues introduced by this change.
- [x] 3.3 Run `openspec validate reshape-oci-melb-1-storage --strict` and confirm the change is ready for implementation/archive flow.
