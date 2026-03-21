# Architecture

**Analysis Date:** 2026-03-21

## Pattern Overview

**Overall:** Single-host flake-driven NixOS composition with legacy `dev-vps` naming and planning docs that describe a future host-centric fleet layout.

**Key Characteristics:**
- `flake.nix` is the only real composition root and builds one system output: `nixosConfigurations.dev-vps` in `flake.nix`.
- Runtime behavior is still centered on one machine configured through `nixos/configuration.nix`, `nixos/digitalocean.nix`, and `nixos/disko-config.nix`.
- Operational control flows through root scripts and recipes in `deploy.sh`, `justfile`, and `.github/workflows/ci.yml` rather than through reusable host/module libraries.

## Layers

**Composition Layer:**
- Purpose: Assemble inputs, overlays, packages, dev shell, and the single NixOS system.
- Location: `flake.nix`
- Contains: Flake inputs, overlay definitions, `packages.x86_64-linux`, `devShells.x86_64-linux.default`, and `nixosConfigurations.dev-vps`.
- Depends on: `./nixos/digitalocean.nix`, `./nixos/configuration.nix`, `./nixos/disko-config.nix`, flake inputs `disko`, `sops-nix`, and `home-manager`.
- Used by: `deploy.sh`, `justfile`, local `nix build`, `nix flake check`, and `.github/workflows/ci.yml`.

**Host Configuration Layer:**
- Purpose: Define the machine's OS, users, services, secret mounts, bootloader, and base packages.
- Location: `nixos/configuration.nix`
- Contains: SSH policy, user accounts, `services.tailscale`, `sops.secrets.*`, custom systemd units, tmpfiles rules, and base packages.
- Depends on: `pkgs`, `modulesPath`, `./disko-config.nix`, and the encrypted secrets file path `../secrets/secrets.yaml`.
- Used by: `flake.nix` as the final host module in `nixosConfigurations.dev-vps`.

**Provider Layer:**
- Purpose: Apply cloud-specific assumptions for the current host.
- Location: `nixos/digitalocean.nix`
- Contains: DigitalOcean guest import, DHCP override, and `services.cloud-init` settings.
- Depends on: `modulesPath` and NixOS DigitalOcean module support.
- Used by: `flake.nix` before the base configuration module.

**Storage Layer:**
- Purpose: Describe disk partitioning and filesystem mounts for bootstrap and rebuilds.
- Location: `nixos/disko-config.nix`
- Contains: One `disk.main` device, GPT partition table, BIOS grub partition, EFI partition, and one ext4 root filesystem.
- Depends on: `disko.nixosModules.disko` from `flake.nix` and a disk device override in `flake.nix:69`.
- Used by: `nixos/configuration.nix` and installation via `deploy.sh`.

**Operations Layer:**
- Purpose: Provide human and CI entrypoints for evaluation, build, deploy, and runtime inspection.
- Location: `justfile`, `deploy.sh`, `.github/workflows/ci.yml`
- Contains: `nix flake check`, local builds, remote `nixos-rebuild`, `nixos-anywhere` install flow, and service status commands.
- Depends on: `flake.nix` outputs and reachable SSH access to the configured host.
- Used by: Operators locally and GitHub Actions in CI.

**Planning And Reference Layer:**
- Purpose: Hold the migration intent and target architecture that the current codebase has not fully implemented yet.
- Location: `README.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, `.planning/PROJECT.md`
- Contains: Fleet-oriented goals, target host `oci-melb-1`, modular host/service plans, and migration decisions.
- Depends on: Manual upkeep; it is not imported by the flake.
- Used by: Future planning and repository reshaping work.

## Data Flow

**Build And Deploy Flow:**

1. Operator runs `nix` commands directly, `just` recipes from `justfile`, or `deploy.sh` from the repo root.
2. `flake.nix` evaluates the single output `nixosConfigurations.dev-vps`, importing `nixos/digitalocean.nix`, `disko`, `sops-nix`, `home-manager`, and `nixos/configuration.nix`.
3. Installation uses `deploy.sh` to call `nixos-anywhere --flake path:.#dev-vps --target-host root@<ip>`; update flow uses `just redeploy` to run `nixos-rebuild --target-host` against the same flake output.
4. On the host, `sops-nix` materializes secret files under `/run/secrets`, `services.tailscale` authenticates with `/run/secrets/tailscale.auth_key`, and `systemd` starts the custom `tailscale-serve-codenomad` unit after Tailscale autoconnect.

**CI Validation Flow:**

1. `.github/workflows/ci.yml` checks out the repo and installs Nix.
2. CI runs `nix flake check --no-build`.
3. CI builds `nixosConfigurations.dev-vps.config.system.build.toplevel` and package outputs for `codenomad`, `opencode`, and `repo-sync`.

**State Management:**
- Declarative state lives in NixOS modules under `flake.nix` and `nixos/*.nix`.
- Secret state is expected in `secrets/secrets.yaml` and is mapped into runtime files via `sops.secrets.*` in `nixos/configuration.nix`.
- Mutable host state is limited to system-managed paths like `/run/secrets`, `/var/lib/sops-nix/key.txt`, and tmpfiles-created directories from `nixos/configuration.nix:159`.

## Key Abstractions

**Single Named Host Output:**
- Purpose: Provide one canonical machine build target.
- Examples: `flake.nix:63`, `justfile:26`, `deploy.sh:14`
- Pattern: All deploy and build entrypoints hard-code `dev-vps` as the system selector.

**Inline Overlay Packages:**
- Purpose: Expose custom packages to both the system and CI.
- Examples: `flake.nix:27`, `flake.nix:44`, `flake.nix:73`
- Pattern: Overlay entries point to `./pkgs/codenomad/package.nix`, `./pkgs/opencode/package.nix`, and `./pkgs/repo-sync/package.nix`, but those paths are currently absent from `pkgs/`.

**Secret-To-File Wiring:**
- Purpose: Keep service credentials out of the Nix store and mount them at runtime.
- Examples: `nixos/configuration.nix:99`, `nixos/configuration.nix:102`, `nixos/configuration.nix:110`, `nixos/configuration.nix:116`
- Pattern: `sops.defaultSopsFile` points to one encrypted YAML file and individual keys are projected to fixed paths in `/run/secrets`.

**Service Publication Through Systemd Glue:**
- Purpose: Bridge native services with Tailscale Serve.
- Examples: `nixos/configuration.nix:145`, `nixos/configuration.nix:154`
- Pattern: A custom oneshot unit runs `tailscale serve --bg` after `tailscaled-autoconnect.service` rather than via a reusable module.

**Scripted Operator Workflows:**
- Purpose: Standardize local admin commands around a single host IP and SSH user.
- Examples: `justfile:3`, `justfile:25`, `justfile:37`, `deploy.sh:4`
- Pattern: Recipes read `DROPLET_IP` and `DROPLET_USER`, then shell out to SSH, `nixos-rebuild`, and `journalctl`.

## Entry Points

**Flake Entry Point:**
- Location: `flake.nix`
- Triggers: `nix build`, `nix flake check`, `nix run`, `nixos-anywhere`, and `nixos-rebuild`.
- Responsibilities: Pin dependencies, define overlays, expose packages, create the dev shell, and assemble the only NixOS host.

**Bootstrap Entry Point:**
- Location: `deploy.sh`
- Triggers: Manual execution with a target IP.
- Responsibilities: Wrap `nixos-anywhere`, select flake target `path:.#dev-vps`, and optionally pass extra files for install-time copying.

**Operator Task Entry Point:**
- Location: `justfile`
- Triggers: `just check`, `just redeploy`, `just logs`, `just status`, `just tailscale-status`, and related commands.
- Responsibilities: Centralize common deploy, build, and remote-debug actions for the current machine.

**Automation Entry Point:**
- Location: `.github/workflows/ci.yml`
- Triggers: `pull_request` and pushes to `main`.
- Responsibilities: Enforce evaluation/buildability of the flake and package outputs.

**Documentation Entry Point:**
- Location: `README.md`
- Triggers: Human readers landing in the repo.
- Responsibilities: Point readers to `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, and `docs/context-history.md` for the active migration story.

## Error Handling

**Strategy:** Mostly fail-fast through Nix evaluation, shell `set -euo pipefail`, and systemd dependency ordering.

**Patterns:**
- Shell scripts in `deploy.sh` and `justfile` stop on command failure rather than doing custom recovery.
- Runtime ordering relies on systemd `after`, `wants`, and `ConditionPathExists` in `nixos/configuration.nix:133` and `nixos/configuration.nix:150`.
- Remote inspection is manual through `journalctl` and `systemctl status` wrappers in `justfile:37` and `justfile:40`.

## Cross-Cutting Concerns

**Logging:** Runtime logs are expected through `journalctl` on the host, surfaced by `just logs` in `justfile:37`.
**Validation:** Structural validation is `nix flake check` plus a full NixOS build in `justfile:28` and `.github/workflows/ci.yml:18`.
**Authentication:** Admin access uses SSH authorized keys from `nixos/configuration.nix:8`; private service access uses `services.tailscale` and the Tailscale Serve unit in `nixos/configuration.nix:124` and `nixos/configuration.nix:145`.

## Current Architectural Reality

**Implemented Shape:**
- Use `flake.nix` + `nixos/*.nix` as the real architecture boundary until the repo is reshaped.
- Treat `nixos/configuration.nix` as the authoritative host module because there is no `hosts/` or `modules/` tree yet.
- Keep operational commands aligned with `dev-vps` because every active script and CI job points to that host name.

**Thin Or Missing Evidence:**
- `home/` and `pkgs/` exist but are empty, while `flake.nix` references `./home/dev.nix` and three package definitions under `./pkgs/*/package.nix`.
- Planning docs in `docs/` and `.planning/` describe a future fleet shape, but that structure is not present in the evaluated code.
- The current runtime code configures Tailscale and legacy `codenomad` exposure; planned `syncthing` and `navidrome` modules are not implemented in this repository snapshot.

---

*Architecture analysis: 2026-03-21*
