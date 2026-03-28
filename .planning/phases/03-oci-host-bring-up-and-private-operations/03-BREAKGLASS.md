# Phase 03 Break-Glass Recovery (oci-melb-1)

Use this runbook when private access fails and normal SSH-over-Tailscale operations cannot recover the host.

## Trigger Conditions

- Tailscale appears down or disconnected on the host.
- SSH is unreachable from the operator machine.
- A pre-change baseline was captured with `just breakglass-baseline` before redeploy.

## Declared Access Contracts (post-reboot)

Break-glass recovery for `oci-melb-1` depends on **both** declarative contracts staying true:

1. OCI console path remains explicitly configured in `modules/providers/oci/default.nix`:
   - `boot.kernelParams = [ "console=ttyAMA0,115200n8" ];`
   - `systemd.services."serial-getty@ttyAMA0"`
2. Recovery SSH keys stay Nix-managed in `hosts/oci-melb-1/users.nix`:
   - `openssh.authorizedKeys.keys = sshKeys;` for both `dev` and `root`
   - `users.mutableUsers = false;`

If either contract drifts, treat it as a break-glass regression and run `just verify-phase-03` before making further host changes.

## Serial Console Access (OCI)

1. Open Oracle Cloud console for the `oci-melb-1` instance.
2. Connect using the **serial console** (ttyAMA0) for out-of-band recovery access.
3. Authenticate as root or use available emergency credentials.

## Single-User / Recovery Flow

1. Inspect existing system generations:

   ```bash
   nix-env -p /nix/var/nix/profiles/system --list-generations
   ```

2. Identify the generation recorded as known-good during the pre-change `just breakglass-baseline` step.

3. Roll back to that recorded known-good generation:

   ```bash
   sudo /nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch
   ```

4. Restart Tailscale service and verify runtime state:

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
