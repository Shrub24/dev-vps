## 1. Define host storage hygiene policy

- [x] 1.1 Add declarative Nix GC/retention settings for `oci-melb-1` in the appropriate host or shared module.
- [x] 1.2 Add journald size and retention limits suitable for a 20G root filesystem.
- [x] 1.3 Add declarative Podman prune service/timer configuration for unused images, containers, and volumes.

## 2. Validate and prepare rollout

- [x] 2.1 Run formatting and targeted evaluation/build checks for the changed NixOS configuration.
- [x] 2.2 Review the resulting config shape to confirm cleanup settings are scoped appropriately and do not alter unrelated storage mounts or services.

## 3. Complete change hygiene

- [x] 3.1 Update task checkboxes to reflect implementation progress.
- [x] 3.2 Run `openspec validate --strict` and resolve any issues before handoff.
