# Technology Stack

**Analysis Date:** 2026-03-21

## Languages

**Primary:**
- Nix - infrastructure definitions and package assembly in `flake.nix`, `nixos/configuration.nix`, `nixos/digitalocean.nix`, and `nixos/disko-config.nix`

**Secondary:**
- YAML - CI and automation config in `.github/workflows/ci.yml`, dependency update rules in `renovate.json`, and SOPS policy in `.sops.yaml`
- Bash - bootstrap and operator workflow helpers in `deploy.sh` and `justfile`
- Markdown - planning and architecture docs in `README.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, and `.planning/PROJECT.md`

## Runtime

**Environment:**
- Nix with flakes enabled via `nix.settings.experimental-features` in `nixos/configuration.nix` and `use flake` in `.envrc`
- NixOS system output named `dev-vps` in `flake.nix`; current build target is `x86_64-linux` in `flake.nix`

**Package Manager:**
- Nix flakes
- Lockfile: present in `flake.lock`

## Frameworks

**Core:**
- NixOS modules - host configuration composed from `nixos/configuration.nix`, `nixos/digitalocean.nix`, and `nixos/disko-config.nix`
- Flakes - repo entrypoint and output graph in `flake.nix`
- Home Manager - declared as a NixOS module input in `flake.nix`, but the referenced `home/dev.nix` file is currently missing from `home/`

**Testing:**
- `nix flake check` - validation command wired in `justfile` and `.github/workflows/ci.yml`

**Build/Dev:**
- `disko` - declarative disk layout input in `flake.nix` and filesystem definition in `nixos/disko-config.nix`
- `sops-nix` - secret provisioning module enabled in `flake.nix` and consumed in `nixos/configuration.nix`
- `nixos-anywhere` - bootstrap tool included in the dev shell in `flake.nix` and used by `deploy.sh`
- `just` - operator task runner in `justfile`
- GitHub Actions - CI in `.github/workflows/ci.yml`
- Renovate - dependency update automation in `renovate.json`

## Key Dependencies

**Critical:**
- `NixOS/nixpkgs` `nixos-25.11` - stable primary package set pinned in `flake.nix` and locked in `flake.lock`
- `NixOS/nixpkgs` `nixos-unstable` - separate package set used for the default dev shell in `flake.nix`
- `nix-community/disko` - disk provisioning input in `flake.nix`, currently used for a single GPT/ext4 layout in `nixos/disko-config.nix`
- `Mic92/sops-nix` - secret decryption and file materialization in `flake.nix` and `nixos/configuration.nix`
- `nix-community/home-manager` `release-25.11` - user environment integration declared in `flake.nix`

**Infrastructure:**
- `tailscale` - enabled as a NixOS service in `nixos/configuration.nix` and exposed with `tailscale serve`
- `cloud-init` - provider bootstrap integration enabled in `nixos/digitalocean.nix`
- `grub` + EFI boot - bootloader config in `nixos/configuration.nix`
- `direnv` + `nix-direnv` - local shell activation in `nixos/configuration.nix` and `.envrc`
- Dev shell tools `sops`, `age`, `jq`, `yq`, `nix-output-monitor`, `nixfmt`, and `statix` - included in `flake.nix`

## Configuration

**Environment:**
- Flake loading is automatic through `.envrc`
- Operator IP and SSH user defaults come from `DROPLET_IP` and `DROPLET_USER` in `justfile`
- Secret values are not stored in plaintext config; encrypted secrets are referenced from `../secrets/secrets.yaml` in `nixos/configuration.nix`
- SOPS recipient policy currently has one `age` recipient and one broad rule for `secrets/*.yaml` in `.sops.yaml`

**Build:**
- Main build entrypoint is `flake.nix`
- System validation and build commands live in `justfile` and `.github/workflows/ci.yml`
- Deployment bootstrap command lives in `deploy.sh`
- NixOS disk layout is defined in `nixos/disko-config.nix`
- Provider-specific bootstrap behavior is defined in `nixos/digitalocean.nix`

## Platform Requirements

**Development:**
- Nix with flake support
- Linux-compatible shell environment for `direnv`, `just`, `ssh`, and `nix`
- Access to encrypted secrets files under `secrets/` exists, but their contents were not inspected

**Production:**
- Current live code targets a DigitalOcean-style VM named `dev-vps`, with `/dev/vda`, GRUB EFI boot, and `cloud-init` settings in `nixos/digitalocean.nix` and `nixos/configuration.nix`
- Planning docs in `README.md`, `docs/architecture.md`, and `.planning/PROJECT.md` target a future Oracle Cloud `oci-melb-1` host, but that target is not yet implemented in code
- Custom package outputs are declared for `./pkgs/codenomad/package.nix`, `./pkgs/opencode/package.nix`, and `./pkgs/repo-sync/package.nix` in `flake.nix`, but `pkgs/` is currently empty

---

*Stack analysis: 2026-03-21*
