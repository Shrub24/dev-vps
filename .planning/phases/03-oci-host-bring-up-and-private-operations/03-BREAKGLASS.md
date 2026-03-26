# Phase 03 Break-Glass Recovery (oci-melb-1)

Use this runbook when private access fails and normal SSH-over-Tailscale operations cannot recover the host.

## Trigger Conditions

- Tailscale appears down or disconnected on the host.
- SSH is unreachable from the operator machine.

## Serial Console Access (OCI)

1. Open Oracle Cloud console for the `oci-melb-1` instance.
2. Connect using the **serial console** for out-of-band recovery access.
3. Authenticate as root or use available emergency credentials.

## Single-User / Recovery Flow

1. Inspect existing system generations:

   ```bash
   nix-env -p /nix/var/nix/profiles/system --list-generations
   ```

2. Roll back to a known-good generation:

   ```bash
   sudo /nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch
   ```

3. Restart Tailscale service and verify runtime state:

   ```bash
   sudo systemctl restart tailscaled
   sudo tailscale status
   ```

## Post-Recovery Validation Checklist

Run after rollback to confirm host state and private access posture:

```bash
hostnamectl
systemctl is-active tailscaled
```

From operator machine:

```bash
just tailscale-status
```

Expected outcome:
- `hostnamectl` reports `oci-melb-1`.
- `tailscaled` returns `active`.
- `just tailscale-status` returns healthy peer status from operator context.
