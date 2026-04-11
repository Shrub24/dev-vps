# Spec: Operations

## Capability ID

`operations`

## Summary

Operations provide a consistent command‑line interface for day‑2 host management, including contract verification, deployment, status monitoring, host‑key management, break‑glass baseline capture, and bootstrap preflight checks. The workflow is centered on the `just` task runner and enforces phase‑specific contract tests before any host change.

## Behaviors

### Contract Verification

- **OP‑1**: The repository shall provide per‑phase contract tests (`tests/phase-*.sh`) that assert critical configuration literals and guard against regression.
- **OP‑2**: The `just` command‑line tool shall offer `verify-phase-*` shortcuts (e.g., `just verify-phase-03`) that run the corresponding contract test suite.
- **OP‑3**: Contract tests shall use `rg` (ripgrep) with fixed‑string patterns to validate exact Nix literals, avoiding generic regular expressions that could mask drift.
- **OP‑4**: Contract failures shall block further deployment steps until the underlying configuration is corrected.

### Deployment

- **OP‑5**: The `just deploy` command shall deploy a host using `deploy‑rs` with `--skip-checks` and optional rollback (`--auto-rollback false`).
- **OP‑6**: The `just activate` command shall perform a dry‑activate of a deployment using `deploy‑rs --dry-activate`.
- **OP‑7**: The `just redeploy` command shall invoke `just deploy` with default rollback behavior (`rollback=true`).
- **OP‑8**: Deployment shall target the host’s NixOS configuration defined in `nixosConfigurations.<host>`.
- **OP‑9**: The deploy workflow shall **not** rely on legacy ad‑hoc scripts; the sole entry point is `just deploy` (or `just redeploy`).

### Host Status and Observability

- **OP‑10**: The `just status` command shall SSH to the host and report `hostnamectl` output plus `systemctl status tailscaled`.
- **OP‑11**: The `just tailscale-status` command shall SSH to the host and run `tailscale status` to verify peer connectivity.
- **OP‑12**: The `just logs` command shall retrieve journal logs for a specified systemd unit (`-n` lines, default 200).
- **OP‑13**: The `just ssh` and `just ssh-root` commands shall provide quick SSH access to the host as `dev` or `root` user.

### Host‑Key and Age Recipient Management

- **OP‑14**: The `just host-age` command shall retrieve the host’s SSH ed25519 public key via `ssh-keyscan`, convert it to an `age` recipient using `ssh-to-age`, and optionally update the `.sops.yaml` anchor.
- **OP‑15**: The `just host-age-from-key` command shall convert a provided SSH public key string to an `age` recipient and optionally update `.sops.yaml`.
- **OP‑16**: Both commands shall support a preview mode (`update=false`) and a write mode (`update=true`) that modifies the `.sops.yaml` file in place.
- **OP‑17**: The host‑age workflow shall be used during secret bootstrap to add new host recipients without manual key transcription.

### Break‑Glass Baseline

- **OP‑18**: The `just breakglass` command shall SSH to the host and report `hostnamectl`, the current system profile link, and the list of NixOS generations.
- **OP‑19**: The operator shall run `just breakglass-baseline` (or equivalent manual recording) before any host update to capture the current generation as a known‑good rollback point.
- **OP‑20**: Break‑glass recovery shall rely on the declarative SSH keys and serial console contracts validated by phase‑03 access tests.

### Build and Check

- **OP‑21**: The `just check` command shall run `nix flake check` (without building) to validate flake outputs and schema.
- **OP‑22**: The `just build` command shall build the toplevel derivation for a specified host (`config.system.build.toplevel`) without switching.
- **OP‑23**: The repository shall provide a `just preflight` command that verifies OpenSSH is enabled, firewall allows TCP/22, and both `dev` and `root` have declarative SSH keys.

### Bootstrap

- **OP‑24**: The `just bootstrap` command shall invoke `deploy.sh` with host‑specific configuration resolved via `scripts/resolve-host-config.sh`.
- **OP‑25**: Bootstrap shall perform a port‑22 reachability check before attempting remote installation.
- **OP‑26**: Bootstrap shall use `nixos-anywhere` (via `deploy.sh`) to install the host from repository‑defined state.

### Secret Bootstrap Integration

- **OP‑27**: The secret bootstrap workflow (`02-SECRETS-BOOTSTRAP.md`) shall reference `just derive-host-age` (now `just host-age`) for adding host recipients to `.sops.yaml`.
- **OP‑28**: Secret provisioning shall be a two‑step process: base system install first, then host recipient addition and encrypted secret deployment.

### Operator Discipline

- **OP‑29**: The canonical day‑2 routine (per `03-OPERATIONS.md`) shall be: verify phase contracts → capture break‑glass baseline → redeploy → verify host health and Tailscale status.
- **OP‑30**: Any deviation from declared contracts (e.g., missing SSH keys, disabled serial console) shall be treated as a regression and fixed before proceeding.

## Constraints

- Deployment uses `deploy‑rs` but rollback behavior can be disabled (`rollback=false`).
- Host‑key age conversion assumes the host uses an ed25519 SSH key; other key types are not supported.
- Bootstrap assumes the target host is reachable on TCP/22 with a temporary bootstrap user (e.g., `ubuntu`, `root`).
- Contract tests are phase‑specific and must be updated when the corresponding configuration changes.

## Verification

- `just verify-phase-03` runs access, operations, and bootstrap contract tests.
- `just verify-phase-04` runs Syncthing and service‑flow contract tests.
- `just verify-phase-04.2` runs Beets promotion contract tests.
- `just check` validates the flake structure.
- `just preflight <host>` ensures OpenSSH, firewall, and SSH key invariants before deployment.