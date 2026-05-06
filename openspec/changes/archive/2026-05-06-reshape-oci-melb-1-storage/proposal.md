## Why

`oci-melb-1` was recovered after a live storage migration left `/nix` unavailable during boot, which exposed gaps between the intended single-disk storage layout, the declarative repo state, and the operator recovery path. We need to codify the new single-disk shape, remove storage-setup drift that causes duplicate tmpfiles behavior, and document the validated recovery workflow so future storage changes stay recoverable.

## What Changes

- Declare the recovered `oci-melb-1` single-disk layout as the canonical host storage baseline, including dedicated `/nix`, `/srv/data`, and `/srv/media` mounts on the OCI boot volume.
- Tighten storage-related directory creation and mount expectations so media and service-state paths are created declaratively without duplicate tmpfiles ownership rules.
- Add an operator recovery runbook covering offline rebuild, chroot rescue requirements, ESP mounting, and post-recovery validation.
- Add validation tasks to confirm the reshaped host configuration, tmpfiles behavior, and key music/media paths evaluate cleanly.

## Capabilities

### New Capabilities
- `host-storage-recovery`: Canonical recovery and reshape workflow for hosts that move storage layout while preserving bootability and service data contracts.

### Modified Capabilities
- `bootstrap-storage`: Update the storage contract so the `oci-melb-1` baseline can declare `/`, `/nix`, `/srv/data`, and `/srv/media` on one disk using stable partition labels.
- `operations`: Extend operator recovery guidance with the validated offline rescue and post-recovery verification workflow.

## Impact

- Affected code: `hosts/oci-melb-1/default.nix`, `modules/storage/disko-single-disk.nix`, music/media-related modules, and docs/runbooks.
- Affected systems: `oci-melb-1` storage layout, tmpfiles-driven directory creation, offline recovery workflow.
- Dependencies: existing `disko`, NixOS tmpfiles behavior, OCI rescue-instance workflow, and current music application modules.
