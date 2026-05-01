# External Integrations

**Analysis Date:** 2026-03-21

## APIs & External Services

**Private Access And Networking:**
- Tailscale - private network access for the host defined in `nixos/configuration.nix`
  - SDK/Client: NixOS `services.tailscale` module and `${pkgs.tailscale}` CLI in `nixos/configuration.nix`
  - Auth: `tailscale/auth_key` materialized as `/run/secrets/tailscale.auth_key` from `sops.secrets.tailscale_auth_key` in `nixos/configuration.nix`
- Tailscale Serve - HTTPS exposure of local service `http://127.0.0.1:9899` via `systemd.services.tailscale-serve-codenomad` in `nixos/configuration.nix`
  - SDK/Client: `${pkgs.tailscale}/bin/tailscale serve`
  - Auth: reuses Tailscale device auth from `services.tailscale` in `nixos/configuration.nix`

**Version Control And Automation:**
- GitHub Actions - CI pipeline in `.github/workflows/ci.yml`
  - SDK/Client: hosted actions `actions/checkout@v4` and `cachix/install-nix-action@v27`
  - Auth: built-in `${{ secrets.GITHUB_TOKEN }}` in `.github/workflows/ci.yml`
- Renovate - dependency update bot configured in `renovate.json`
  - SDK/Client: Renovate GitHub app/config file
  - Auth: handled externally by Renovate; no repo-local token config detected

**Repository-Managed Secrets Consumers:**
- GitHub API token consumer - secret path `/run/secrets/github.token` declared by `sops.secrets.github_token` in `nixos/configuration.nix`
  - SDK/Client: not detected in code; secret is provisioned for runtime use
  - Auth: `github/token` key in encrypted `secrets/secrets.yaml` referenced by `nixos/configuration.nix`
- CodeNomad environment consumer - secret path `/run/secrets/codenomad.env` declared by `sops.secrets.codenomad_env` in `nixos/configuration.nix`
  - SDK/Client: custom `codenomad` package declared in `flake.nix`
  - Auth: `codenomad/env` key in encrypted `secrets/secrets.yaml` referenced by `nixos/configuration.nix`

## Data Storage

**Databases:**
- Not detected in the current codebase
  - Connection: Not applicable
  - Client: Not applicable

**File Storage:**
- Encrypted SOPS files under `secrets/` with policy in `.sops.yaml`; plaintext values are projected at runtime into `/run/secrets/*` by `sops-nix` from `nixos/configuration.nix`
- Host filesystem storage is local ext4 on `/` with EFI boot partition in `nixos/disko-config.nix`

**Caching:**
- None detected in repo-local configuration

## Authentication & Identity

**Auth Provider:**
- SSH public key auth - enabled for `root` and `dev` in `nixos/configuration.nix`
  - Implementation: static authorized keys embedded in `nixos/configuration.nix`
- SOPS + age - secrets decryption path configured in `.sops.yaml` and `nixos/configuration.nix`
  - Implementation: `sops.age.keyFile = "/var/lib/sops-nix/key.txt"` in `nixos/configuration.nix`
- Tailscale device enrollment - configured in `nixos/configuration.nix`
  - Implementation: auth key file consumed by `services.tailscale.authKeyFile`

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- `journalctl` over SSH via `just logs` in `justfile`
- Service status inspection via `just status`, `just tailscale-status`, and `just hm-status` in `justfile`

## CI/CD & Deployment

**Hosting:**
- Current code is provider-coupled to DigitalOcean through `nixos/digitalocean.nix` and `DROPLET_IP` defaults in `justfile`
- Planning docs in `README.md` and `docs/architecture.md` point to Oracle Cloud `oci-melb-1`, but no Oracle-specific Nix module exists yet

**CI Pipeline:**
- GitHub Actions in `.github/workflows/ci.yml`
- Build checks run `nix flake check --no-build`, system build for `nixosConfigurations.dev-vps`, and package builds for `packages.x86_64-linux.*`

## Environment Configuration

**Required env vars:**
- `DROPLET_IP` - deployment/status target in `justfile`
- `DROPLET_USER` - SSH user in `justfile`
- Secrets for `tailscale/auth_key`, `github/token`, and `codenomad/env` are required in encrypted `secrets/secrets.yaml` referenced by `nixos/configuration.nix`

**Secrets location:**
- Policy: `.sops.yaml`
- Encrypted files present: `secrets/secrets.yaml` and `secrets/secrets.template.yaml`
- Runtime materialization: `/run/secrets/codenomad.env`, `/run/secrets/tailscale.auth_key`, and `/run/secrets/github.token` from `nixos/configuration.nix`

## Webhooks & Callbacks

**Incoming:**
- DigitalOcean `cloud-init` datasource integration in `nixos/digitalocean.nix`
- GitHub webhook-style CI triggers on `push` to `main` and all `pull_request` events in `.github/workflows/ci.yml`

**Outgoing:**
- `deploy.sh` invokes `nix run github:nix-community/nixos-anywhere -- --target-host root@<ip>` for remote installation
- `just redeploy` uses `nixos-rebuild --target-host` and `--build-host` over SSH in `justfile`
- Tailscale Serve publishes outbound HTTPS registration through the local Tailscale node in `nixos/configuration.nix`

---

*Integration audit: 2026-03-21*
