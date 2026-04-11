# Spec: Admin Services

## Capability ID

`admin-services`

## Summary

Admin services provide secure, private administrative access to fleet hosts via Tailscale SSH, a web‑based terminal (Termix) exposed through Tailscale Serve, and break‑glass recovery via provider serial console. Access is restricted to the Tailscale interface (`tailscale0`) with no public firewall openings, and operator routines are documented for day‑2 operations and emergency recovery.

## Behaviors

### Tailscale Integration

- **AD‑1**: Tailscale shall be enabled with `openFirewall = false` and `extraSetFlags = [ "--ssh" ]` to allow SSH over Tailscale.
- **AD‑2**: Tailscale shall not define any `serve` or `funnel` configurations in its base module; service exposure is layered via `admin.nix`.
- **AD‑3**: The host firewall shall allow TCP port 22 **only** on the `tailscale0` interface (`trustedInterfaces = [ "tailscale0" ]`).

### Termix Web Terminal

- **AD‑4**: Termix shall run as a Podman container with image `ghcr.io/lukegus/termix:release‑2.0.0` on host port `8083` bound to `0.0.0.0`.
- **AD‑5**: Termix shall depend on a `guacd` container (`guacamole/guacd:1.6.0`) for terminal emulation.
- **AD‑6**: Termix container shall be configured with DNS `100.100.100.100` (Tailscale MagicDNS) and `1.1.1.1` (fallback), and DNS search domain matching the tailnet (`tail0fe19b.ts.net`).
- **AD‑7**: Termix data and guacd state shall reside under `/srv/data/termix/` with appropriate tmpfiles rules.
- **AD‑8**: Termix **shall not** open any public firewall ports; exposure is solely via Tailscale Serve.

### Tailscale Serve Exposure

- **AD‑9**: A dedicated systemd service (`tailscale-serve-termix`) shall configure Tailscale Serve to expose Termix via HTTPS on port `8443`, reverse‑proxying to `http://127.0.0.1:8083`.
- **AD‑10**: The service shall start after `tailscaled` and `podman-termix` are ready, and shall stop the Serve mapping on service shutdown.
- **AD‑11**: The Serve configuration **shall not** use Tailscale Funnel (public internet exposure) or path‑based routing (`/termix`).
- **AD‑12**: An activation script shall restart the Serve service after system activation to ensure mapping persists across rebuilds.

### SSH Key Management

- **AD‑13**: SSH public keys shall be declared centrally in `modules/core/users.nix` as a list `sshKeys`.
- **AD‑14**: The `dev` user and `root` user shall both have `openssh.authorizedKeys.keys` set to `sshKeys`.
- **AD‑15**: User mutability shall be disabled (`users.mutableUsers = false`) to prevent manual key modifications outside Nix management.
- **AD‑16**: The users module shall assert that `sshKeys` is non‑empty, guaranteeing at least one key is present for recovery.

### Break‑Glass Recovery

- **AD‑17**: For Oracle Cloud hosts, the provider module (`modules/providers/oci/default.nix`) shall enable serial console via kernel parameter `console=ttyAMA0,115200n8` and a `systemd.service."serial-getty@ttyAMA0"` unit.
- **AD‑18**: A break‑glass runbook (`03-BREAKGLASS.md`) shall document serial console access, generation rollback using `nix-env --list-generations`, and Tailscale service restart.
- **AD‑19**: The operator shall capture a pre‑change baseline with `just breakglass-baseline` before any host update, recording the current NixOS generation as known‑good.
- **AD‑20**: Recovery shall rely on the declarative SSH keys and serial console contracts; any drift in these contracts shall be treated as a regression.

### Operator Routines

- **AD‑21**: A day‑2 operations runbook (`03-OPERATIONS.md`) shall define the canonical update sequence: verify phase contracts → capture break‑glass baseline → redeploy → verify host health and Tailscale status.
- **AD‑22**: The `just` command‑line tool shall provide shortcuts for `verify-phase-03`, `breakglass-baseline`, `redeploy`, `status`, and `tailscale-status`.
- **AD‑23**: The `just redeploy` command shall use `nixos-rebuild --target-host` (or equivalent) and **shall not** adopt fleet deployment tooling (`deploy‑rs`) until Phase 06.

### Contract Enforcement

- **AD‑24**: The access contract test (`tests/phase-03-access-contract.sh`) shall validate Tailscale, Termix, admin module, firewall, SSH key, and break‑glass configuration literals.
- **AD‑25**: The contract test shall guard against regressions such as public firewall openings, Funnel usage, path‑based Serve routes, legacy container images, and mutable user settings.

## Constraints

- All admin access is private and Tailscale‑only; no public ports are opened on the host firewall.
- Termix exposure uses Tailscale Serve HTTPS on a dedicated port (`8443`), not native TLS termination in the container.
- Break‑glass recovery assumes provider‑specific serial console availability (OCI ttyAMA0) and declarative SSH keys.
- Fleet deployment tooling (`deploy‑rs`) is deferred to Phase 06; day‑2 updates use host‑targeted `nixos-rebuild`.

## Verification

- `tests/phase-03-access-contract.sh` validates the complete admin access stack.
- `just verify-phase-03` runs the access contract test along with other phase‑03 contracts.
- `just breakglass-baseline` captures the current system generation for recovery tracking.
- `just tailscale-status` confirms Tailscale peer connectivity and Serve mapping from the operator machine.