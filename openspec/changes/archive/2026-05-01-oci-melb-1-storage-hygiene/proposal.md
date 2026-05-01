## Why

`oci-melb-1` is running out of root-disk space during normal operation because the host currently retains too much local state across Nix generations, journald logs, and Podman image/container storage. We need a declarative storage-hygiene baseline now so the first host stays recoverable and deployable without depending on ad-hoc manual cleanup.

**Core Value:** Keep `oci-melb-1` reliably operable on Oracle Cloud free-tier storage by enforcing a low-complexity, repo-managed storage hygiene policy for Nix, journald, and container state.

## What Changes

- Add a host storage-hygiene policy for `oci-melb-1` that enables automatic Nix garbage collection and store optimisation with retention suitable for deploy-rs remote builds.
- Add journald retention and size limits so log growth cannot silently consume most of the root filesystem.
- Add declarative Podman image/container cleanup timers so stale container artifacts do not accumulate indefinitely on the root filesystem.
- Document the scope of this change as an operational baseline for root-disk pressure reduction, not as a disk-layout redesign or `/nix` migration.

## Capabilities

### New Capabilities
- `host-storage-hygiene`: Provide a declarative host baseline for Nix retention, journald retention, and Podman cleanup so storage pressure remains bounded during routine operations.

### Modified Capabilities

## Impact

- **Affected code**: `hosts/oci-melb-1/default.nix` and/or shared host baseline modules that define Nix, journald, and Podman behavior.
- **Operational impact**: `oci-melb-1` will automatically reclaim stale Nix, logs, and container artifacts instead of relying on manual emergency cleanup.
- **Risk boundary**: This change intentionally reduces retained rollback/build/cache state and container artifacts; it does not change disk partitions, media data layout, or add new paid infrastructure.
