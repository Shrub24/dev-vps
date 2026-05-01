# Phase 03 Bootstrap Runbook (oci-melb-1)

This runbook defines the canonical OCI bootstrap sequence aligned to the enforced contract checks.

## Operator Sequence

1. Run preflight evaluation:

   ```bash
    just flake-check
    ```

2. Run bootstrap access safety preflight (required before bootstrap/deploy):

   ```bash
   just bootstrap-preflight host=oci-melb-1
   ```

3. Confirm bootstrap/storage contract invariants:

   ```bash
   bash tests/phase-03-bootstrap-contract.sh
   ```

4. Execute remote install (recommended via `just` entrypoint):

   ```bash
   just bootstrap BOOTSTRAP_TARGET=<oci_public_ip_or_dns>
   ```

   Optional overrides for non-default bootstrap identity/flake/extra-files:

   ```bash
   just bootstrap \
     BOOTSTRAP_TARGET=<oci_public_ip_or_dns> \
     BOOTSTRAP_USER=<bootstrap_user> \
     BOOTSTRAP_FLAKE=path:.#oci-melb-1 \
     BOOTSTRAP_EXTRA_FILES=<extra-files-path>
   ```

   Hardware config generation is enabled by default and writes to
   `hosts/oci-melb-1/hardware-configuration.nix` using `nixos-generate-config`.

   Optional hardware generation controls:

   ```bash
   just bootstrap \
     BOOTSTRAP_TARGET=<oci_public_ip_or_dns> \
     BOOTSTRAP_HARDWARE_CONFIG_GENERATOR=nixos-generate-config \
     BOOTSTRAP_HARDWARE_CONFIG_PATH=hosts/oci-melb-1/hardware-configuration.nix
   ```

   To skip hardware generation entirely:

   ```bash
   just bootstrap \
     BOOTSTRAP_TARGET=<oci_public_ip_or_dns> \
     BOOTSTRAP_SKIP_HARDWARE_CONFIG=true
   ```

   Equivalent direct script usage remains available:

   ```bash
   ./deploy.sh --target <oci_public_ip_or_dns> --bootstrap-user <bootstrap_user> --flake path:.#oci-melb-1 --extra-files <extra-files-path>
   ```

   Direct script flags for hardware generation are also available:

   - `--hardware-config-generator <name>`
   - `--hardware-config-path <path>`
   - `--skip-hardware-config`

5. Validate expected hostname output from flake:

   ```bash
   nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.networking.hostName
   ```

6. Keep access private-first:
   - This bootstrap flow remains Tailscale-first.
   - Do not add public ingress as part of this procedure.

## Troubleshooting (First Boot)

Run on the host (or via recovery shell) to validate disk and service readiness:

```bash
lsblk -f
findmnt /srv/data
systemctl status tailscaled
```

- `lsblk -f` should show labeled ext4 partitions (`rootfs`, `srv-data`).
- `findmnt /srv/data` should confirm the persistent data mount is active.
- `systemctl status tailscaled` should confirm the Tailscale daemon is running for private access.

## Bootstrap Config Source of Truth

Default bootstrap values are defined in:

- `hosts/oci-melb-1/bootstrap-config.nix`

This file currently pins:

- `hostName = "oci-melb-1"`
- `bootstrapUser = "ubuntu"` (OCI image bootstrap user)
- `bootstrapDisk = "/dev/sda"`
- `flake = "path:.#oci-melb-1"`
- `hardwareConfigGenerator = "nixos-generate-config"`
- `hardwareConfigPath = "hosts/oci-melb-1/hardware-configuration.nix"`
