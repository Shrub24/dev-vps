# Phase 03 Bootstrap Runbook (oci-melb-1)

This runbook defines the canonical OCI bootstrap sequence aligned to the enforced contract checks.

## Operator Sequence

1. Run preflight evaluation:

   ```bash
   just flake-check
   ```

2. Confirm bootstrap/storage contract invariants:

   ```bash
   bash tests/phase-03-bootstrap-contract.sh
   ```

3. Execute remote install:

   ```bash
   ./deploy.sh <oci_public_ip_or_dns> [extra-files]
   ```

4. Validate expected hostname output from flake:

   ```bash
   nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.networking.hostName
   ```

5. Keep access private-first:
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
