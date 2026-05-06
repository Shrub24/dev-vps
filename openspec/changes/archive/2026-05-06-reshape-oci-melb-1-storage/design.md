## Overview

This change makes the recovered `oci-melb-1` layout the canonical declarative baseline and closes the operational gaps exposed during rescue. The design keeps the recovered partitioning simple: root, data, nix, and media remain separate ext4 filesystems on the OCI boot volume, referenced by stable partlabels. The follow-up work focuses on three areas: declarative storage layout fidelity, media/tmpfiles consistency, and operator recovery documentation.

## Goals

- Preserve the working single-disk recovery layout in repository state.
- Ensure the evaluated host filesystem contract matches the real OCI partition map.
- Remove duplicate tmpfiles directory ownership declarations for shared media paths.
- Ensure required media/service directories are created declaratively on boot.
- Capture the proven offline recovery sequence as canonical operator guidance.

## Non-Goals

- Repartitioning `oci-melb-1` again.
- Introducing a second-disk storage model for the first host.
- Redesigning the whole music application stack.
- Changing secret topology beyond what the recovery/runbook needs.

## Storage Shape

The canonical `oci-melb-1` layout after recovery is:

- EFI system partition on the OCI boot volume
- ext4 root on `disk-main-root`
- ext4 service-state filesystem on `disk-main-data` mounted at `/srv/data`
- ext4 Nix store filesystem on `disk-main-nix` mounted at `/nix`
- ext4 media filesystem on `disk-main-media` mounted at `/srv/media`

This layout remains host-specific and is expressed through `disko-single-disk.nix` plus host-provided sizing options.

## Media Directory Ownership Strategy

The current repo defines some media directories from multiple modules. The cleanup will consolidate directory-creation ownership so each shared media path has one authoritative tmpfiles owner while other modules may still layer ACL or marker-file behavior. This avoids duplicate tmpfiles warnings while preserving the intended permissions model for Syncthing, Beets, and related services.

## Recovery Runbook Strategy

The runbook will document the validated rescue flow:

1. Attach the broken boot volume to a rescue instance.
2. Mount root, `/nix`, `/srv/media`, and the ESP.
3. Bind `/dev`, `/proc`, `/sys`, `/run` and provide DNS in chroot.
4. Build the target system closure with sandbox disabled when required in rescue chroot.
5. Run `switch-to-configuration boot` with the mounted ESP.
6. Unmount cleanly, reattach the boot volume, and validate host boot plus mount/service health.

## Validation Plan

- Evaluate `nixosConfigurations.oci-melb-1.config.fileSystems` and relevant tmpfiles output.
- Run `nix flake check` using a path source so untracked files required by evaluation are included.
- Verify no duplicate tmpfiles directory rules remain for canonical shared media directories.
- Confirm documented post-recovery operator checks cover bootability, mounts, and key service paths.
