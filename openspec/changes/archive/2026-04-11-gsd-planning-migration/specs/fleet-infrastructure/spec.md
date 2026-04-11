# Spec: Fleet Infrastructure Capability

## Capability ID

`fleet-infrastructure`

## Summary

This repository serves as the infrastructure source of truth for a modular NixOS homelab fleet, initially targeting Oracle Cloud Free Tier with `oci-melb-1` as the first concrete host.

## Behaviors

### Host Management

- **HB-1**: The repository shall provide a host-centric module layout that separates host identity from reusable service modules.
- **HB-2**: The repository shall support `aarch64-linux` as the primary architecture for the first host.
- **HB-3**: The repository shall be extendable to additional hosts without requiring structural rewrites.
- **HB-4**: Each host shall have isolated secret scoping that does not grant decryption access to other hosts by default.

### Bootstrap

- **BOOT-1**: The host shall be bootstrappable via `nixos-anywhere` from repository-defined state.
- **BOOT-2**: The host disk layout shall be declared declaratively using `disko`.
- **BOOT-3**: The host shall be rebuildable repeatably from the flake after initial installation.

### Secrets Management

- **SECR-1**: Fleet-shared secrets shall be stored in `secrets/common.yaml` with restricted recipient policy.
- **SECR-2**: Host-specific secrets shall be stored in `hosts/<host>/secrets.yaml` with host-scoped recipients.
- **SECR-3**: The `.sops.yaml` policy shall define explicit rules that prevent new hosts from automatically gaining access to existing host secrets.
- **SECR-4**: Tailscale enrollment material shall be host-scoped, not shared across hosts.

### Network and Access

- **NET-1**: All management and service access shall be private and Tailscale-first.
- **NET-2**: Public service exposure shall not be part of the baseline configuration.
- **NET-3**: A documented break-glass recovery path shall exist for SSH/Tailscale failures.

### Storage Model

- **STOR-1**: One persistent service-state mount shall be mounted at `/srv/data` with predictable subdirectories.
- **STOR-2**: One dedicated media filesystem shall be mounted at `/srv/media` for authoritative media storage.
- **STOR-3**: Stable device identifiers shall be used for mounts, not transient `/dev/sdX` names.

### Media Services

- **MEDIA-1**: Syncthing shall be configurable declaratively with persistent paths and explicit folder modes.
- **MEDIA-2**: Syncthing shall have versioning or conflict safeguards enabled to reduce accidental delete risk.
- **MEDIA-3**: Navidrome shall read directly from the Syncthing-managed media path without duplicate staging.
- **MEDIA-4**: Beets shall operate as an inbox-only singleton tagging worker against `/srv/media/inbox`.
- **MEDIA-5**: Beets shall support transfer-safe automation: `.tmp` lockout, settle/debounce, post-run demotion to `/srv/media/untagged`.
- **MEDIA-6**: Beets shall preserve original filenames during promotion to `/srv/media/library`.
- **MEDIA-7**: Beets state and reporting shall be isolated under `/srv/data/beets`.

### Operations

- **OPER-1**: Routine configuration changes shall be applicable through host-targeted `nixos-rebuild`.
- **OPER-2**: Architecture, plan, and decision documents shall remain authoritative for behavior and trust-boundary changes.
- **OPER-3**: Executable contract tests shall verify bootstrap, access, and service invariants.

## Constraints

- First host targets Oracle Cloud Free Tier on `aarch64-linux`
- Fleet direction supports mixed `aarch64` and `x86_64` hosts
- Secrets scoped by blast radius with explicit `.sops.yaml` rules
- Services remain private and Tailscale-only in baseline
- Complexity deferred until real pressure exists: no early Kubernetes, no public ingress, no premature fleet tooling
