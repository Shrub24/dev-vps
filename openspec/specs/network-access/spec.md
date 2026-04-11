# Spec: Network Access

## Capability ID

`network-access`

## Summary

The repository enforces a private‑first network access model where all management and service traffic flows over Tailscale. Public firewall ports are closed by default; services remain private/Tailscale‑only in the baseline. Break‑glass recovery paths are documented for serial‑console access when Tailscale fails.

## Behaviors

### Private‑First Posture

- **NET-1**: All management and service access shall be private and Tailscale‑first; public internet exposure is not part of the baseline configuration.
- **NET-2**: The Tailscale module shall explicitly set `openFirewall = false` to prevent accidental drift toward public exposure.
- **NET-3**: Service modules (Navidrome, slskd, etc.) shall also set `openFirewall = false` to ensure no service opens public ports by default.
- **NET-4**: Trust boundaries shall be declared using `networking.firewall.trustedInterfaces = [ "tailscale0" ]` to allow intra‑tailnet traffic while keeping public firewall closed.

### Tailscale Integration

- **TAIL-1**: Tailscale shall be enabled on every host from day‑0 via the reusable `modules/services/tailscale.nix` module.
- **TAIL-2**: Tailscale enrollment shall use host‑scoped auth keys stored in `hosts/<host>/secrets.yaml`, not shared reusable keys.
- **TAIL-3**: The Tailscale service shall be configured with `extraSetFlags = [ "--ssh" ]` to enable Tailscale SSH.
- **TAIL-4**: Tailscale shall automatically connect on boot via `tailscale-autoconnect.service`.

### Admin Access (Termix)

- **ADMIN-1**: Private admin access shall be provided via Termix (web‑based terminal) exposed over Tailscale Serve on HTTPS port 8443.
- **ADMIN-2**: Termix shall run as a Podman container bound to `127.0.0.1:8083`; Tailscale Serve shall proxy `https://<tailnet>:8443` to that local port.
- **ADMIN-3**: The Termix container shall store its state under `/srv/data/termix` with a Podman named volume.
- **ADMIN-4**: A systemd service `tailscale-serve-termix` shall manage the Serve lifecycle, starting after Tailscale and Termix are ready.
- **ADMIN-5**: Termix shall **not** enable Tailscale Funnel, public ingress, or native HTTPS; all exposure is via Tailscale Serve only.

### Firewall and SSH

- **FW-1**: The host firewall shall allow only TCP/22 (SSH) on public interfaces for bootstrap and break‑glass recovery.
- **FW-2**: SSH shall be configured with declarative authorized keys for `dev` and `root` users, sourced from a central `sshKeys` list.
- **FW-3**: User mutability shall be disabled (`users.mutableUsers = false`) to enforce that all SSH key changes flow through Nix configuration.
- **FW-4**: A preflight check (`just bootstrap-preflight`) shall validate that TCP/22 is open and declarative SSH keys are present before bootstrap/deploy operations.

### Break‑Glass Recovery

- **BG-1**: A documented break‑glass recovery path shall exist for when Tailscale and SSH are unreachable.
- **BG-2**: For OCI hosts, serial‑console access shall be enabled via `boot.kernelParams = [ "console=ttyAMA0,115200n8" ]` and a systemd serial‑getty service.
- **BG-3**: Recovery shall follow a command‑level runbook (`03-BREAKGLASS.md`) that includes generation listing, rollback to a known‑good generation, and Tailscale restart.
- **BG-4**: A baseline capture command (`just breakglass-baseline`) shall record the current generation before risky changes, providing a rollback target.

### Contract Enforcement

- **CONTRACT-1**: Network‑access invariants shall be enforced by executable contract tests (`tests/phase-03-access-contract.sh`).
- **CONTRACT-2**: Contract tests shall verify:
  - Tailscale `openFirewall = false`
  - Trusted interface `tailscale0`
  - Absence of public‑ingress patterns (Funnel, native HTTPS, path‑based Serve)
  - Serial‑console kernel parameters
  - Declarative SSH key wiring
- **CONTRACT-3**: Any deviation from private‑first posture shall cause contract tests to fail.

### Operations

- **OPS-1**: Operators shall use `just tailscale-status` to check peer health from the management machine.
- **OPS-2**: The `just derive-host-age` command shall support preview and update modes for deriving age recipients from live SSH host keys.
- **OPS-3**: Service exposure changes (e.g., opening a public port) must be explicitly justified and tracked as a security‑boundary change.

## Constraints

- First host `oci-melb-1` uses OCI serial console for break‑glass; second host `do-admin-1` may have different recovery mechanisms.
- Tailscale Serve is used only for Termix (port 8443); other services remain accessible via Tailscale IP/DNS without additional proxying.
- No public reverse proxy or tunnel is included in baseline; internet exposure deferred until hardening is complete.
- Complexity deferred: no load‑balancing, no DDoS protection, no WAF, no multi‑region mesh beyond Tailscale.

## Examples

### Tailscale Module (`modules/services/tailscale.nix`)
```nix
{
  services.tailscale = {
    enable = true;
    openFirewall = false;
    extraSetFlags = [ "--ssh" ];
  };
}
```

### Firewall Configuration (`hosts/oci-melb-1/default.nix` excerpt)
```nix
{
  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };
}
```

### Termix Serve Service (`modules/applications/admin.nix` excerpt)
```nix
systemd.services.tailscale-serve-termix = {
  serviceConfig = {
    ExecStart = ''${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=8443 http://127.0.0.1:8083'';
    ExecStop = ''${pkgs.tailscale}/bin/tailscale serve --https=8443 off'';
  };
};
```

### Break‑Glass Commands
```bash
# Capture baseline before risky change
just breakglass-baseline

# Serial‑console recovery (OCI)
nix-env -p /nix/var/nix/profiles/system --list-generations
sudo /nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch
sudo systemctl restart tailscaled
```

## Related Specifications

- [secrets-management](../secrets-management/spec.md) – host‑scoped Tailscale auth keys
- [bootstrap-storage](../bootstrap-storage/spec.md) – bootstrap preflight checks
- [admin-services](../admin-services/spec.md) – Termix and admin tooling
- [operations](../operations/spec.md) – routine host updates and monitoring