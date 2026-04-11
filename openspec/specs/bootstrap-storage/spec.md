# Spec: Bootstrap and Storage

## Capability ID

`bootstrap-storage`

## Summary

The repository provides a declarative bootstrap workflow using `nixos-anywhere` with `disko` for disk partitioning, and establishes a predictable storage model with persistent mounts for service state (`/srv/data`) and media (`/srv/media`). Bootstrap contracts are enforced via executable tests that verify deploy commands, host imports, and disk layout invariants before installation.

## Behaviors

### Bootstrap Contract Enforcement

- **BOOT-1**: The repository shall enforce bootstrap invariants with fixed‑string contract assertions before any host installation attempt.
- **BOOT-2**: Contract tests shall verify the canonical deploy command (`nixos-anywhere`), host‑config wiring, and bootstrap‑config values.
- **BOOT-3**: The operator workflow shall include a preflight check (`just bootstrap-preflight`) that validates SSH access, firewall rules, and declarative SSH keys before bootstrap.
- **BOOT-4**: Bootstrap documentation shall reference only commands covered by executable contract checks.

### Remote Installation

- **BOOT-5**: The primary bootstrap entrypoint shall be `just bootstrap` with configurable target, user, flake, and hardware‑generation options.
- **BOOT-6**: The underlying deploy script (`deploy.sh`) shall invoke `nixos-anywhere` with `--build-on-remote` flag to reduce local resource requirements.
- **BOOT-7**: Hardware configuration generation (`nixos-generate-config`) shall be enabled by default, writing to `hosts/<host>/hardware-configuration.nix`.
- **BOOT-8**: Bootstrap shall support two‑step secret introduction: base install succeeds without host secrets, then host recipient + secrets added post‑install.

### Disk Layout (Disko)

- **STOR-1**: Disk layout shall be declared declaratively using `disko` modules.
- **STOR-2**: The OCI host (`oci-melb-1`) shall use a two‑disk layout:
  - Main disk (`/dev/sda`): GPT with EFI system partition, root partition (`/`), and data partition (`/srv/data`).
  - Media disk (`/dev/sdb`): GPT with single media partition (`/srv/media`).
- **STOR-3**: The DigitalOcean host (`do-admin-1`) shall use a single‑disk layout (`/dev/vda`) with root and data partitions on the same disk.
- **STOR-4**: Filesystems shall be labeled (`rootfs`, `srv-data`, `srv-media`) for stable identification, not transient `/dev/sdX` names.
- **STOR-5**: Data and media mounts shall include `nofail` and `x-systemd.device-timeout=10s` options for graceful boot behavior.

### Storage Model

- **STOR-6**: One persistent service‑state mount shall be mounted at `/srv/data` with predictable subdirectories for each service.
- **STOR-7**: One dedicated media filesystem shall be mounted at `/srv/media` as the authoritative media storage location.
- **STOR-8**: Service state (`/srv/data`) shall be separate from media content (`/srv/media`) to allow independent backup, snapshot, and replication policies.
- **STOR-9**: The media subtree shall be organized as:
  - `/srv/media/library` – canonical promoted library
  - `/srv/media/inbox` – ingest boundary for Beets
  - `/srv/media/quarantine/untagged` – demotion target for inbox leftovers
  - `/srv/media/quarantine/approved` – curated quarantine for manual review
- **STOR-10**: Syncthing shall manage `/srv/media/library` and `/srv/media/quarantine` directly with explicit folder markers (`.stfolder`).

### Provider‑Aware Defaults

- **PROV-1**: OCI‑specific defaults (GRUB device `/dev/sda`, bootstrap user `ubuntu`) shall be isolated in `modules/providers/oci/default.nix`.
- **PROV-2**: DigitalOcean‑specific defaults (GRUB device `/dev/vda`, bootstrap user `root`, `digital‑ocean‑config.nix`) shall be isolated in `modules/providers/digitalocean/default.nix`.
- **PROV-3**: Provider modules shall not leak into reusable service logic; host composition selects appropriate provider module.

### Verification and Troubleshooting

- **VERIF-1**: First‑boot validation shall include `lsblk -f`, `findmnt /srv/data`, and `systemctl status tailscaled` checks.
- **VERIF-2**: Contract tests shall be runnable standalone (`bash tests/phase-03-bootstrap-contract.sh`) and via `just verify-oci-contract`.
- **VERIF-3**: Bootstrap failures shall have a documented break‑glass recovery path (SSH/Tailscale fallback).

## Constraints

- First host is `oci-melb-1` on Oracle Cloud Free Tier (`aarch64-linux`) with two‑disk layout.
- Second host `do-admin-1` on DigitalOcean uses single‑disk layout.
- Fleet direction supports mixed `aarch64` and `x86_64` hosts with provider‑aware disk defaults.
- Complexity deferred: no RAID, LVM, or advanced filesystems (ZFS/btrfs) in baseline; ext4 used for simplicity.

## Examples

### Bootstrap Config (`hosts/oci-melb-1/bootstrap-config.nix`)
```nix
{
  hostName = "oci-melb-1";
  bootstrapUser = "ubuntu";
  bootstrapDisk = "/dev/sda";
  mediaDisk = "/dev/sdb";
  rootPartitionSize = "20G";
  flake = "path:.#oci-melb-1";
  hardwareConfigGenerator = "nixos-generate-config";
  hardwareConfigPath = "hosts/oci-melb-1/hardware-configuration.nix";
}
```

### Disko Root Layout (`modules/storage/disko-root.nix` excerpt)
```nix
disko.devices.disk.main = {
  type = "disk";
  content = {
    type = "gpt";
    partitions = {
      ESP = { size = "512M"; type = "EF00"; ... };
      root = { size = config.disko-root-extra; ... };
      data = { size = "100%"; ... };
    };
  };
};
```

### Bootstrap Commands
```bash
# Preflight
just bootstrap-preflight host=oci-melb-1
bash tests/phase-03-bootstrap-contract.sh

# Install
just bootstrap BOOTSTRAP_TARGET=<oci-public-ip>

# Validate
lsblk -f
findmnt /srv/data
systemctl status tailscaled
```

## Related Specifications

- [secrets-management](../secrets-management/spec.md) – two‑step secret bootstrap
- [fleet-infrastructure](../fleet-infrastructure/spec.md) – overall host management
- [media-services](../media-services/spec.md) – media subtree usage
- [operations](../operations/spec.md) – ongoing host updates