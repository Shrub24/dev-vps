# dev-vps

Reproducible NixOS VPS for mobile OpenCode sessions via CodeNomad + Tailscale.

## Layout

- `flake.nix`: flake entrypoint (`.#dev-vps`)
- `nixos/configuration.nix`: host config, services, users, firewall
- `nixos/disko-config.nix`: GPT + BIOS+UEFI partitioning
- `pkgs/codenomad/package.nix`: pinned `buildNpmPackage` for CodeNomad
- `pkgs/opencode/package.nix`: pinned `buildNpmPackage` for OpenCode
- `secrets/secrets.yaml`: encrypted runtime secrets (sops)
- `deploy.sh`: nixos-anywhere helper

## Deploy

```bash
./deploy.sh <DROPLET_IP> [DISK_DEVICE]
```

Default disk is `/dev/vda`.

## Local test

Build full system:

```bash
nix build --no-link path:.#nixosConfigurations.dev-vps.config.system.build.toplevel
```

Build VM artifact:

```bash
nix build --no-link path:.#nixosConfigurations.dev-vps.config.system.build.vm
```

## Secrets (bootstrap once)

This repo uses `sops-nix`.

1. Generate a VPS age key and store private key at `/var/lib/sops-nix/key.txt`.
2. Add the VPS **public** age key to `.sops.yaml` recipients.
3. Update secret values in `secrets/secrets.yaml` and re-encrypt with `sops`.
4. Redeploy.

Secrets expected:

- `codenomad/env`: env file content (username + password)
- `tailscale/auth_key`: reusable tagged auth key

## Tailscale

- Hostname is `dev-vps`
- Tag advertised: `tag:dev-vps`
- CodeNomad binds localhost on `127.0.0.1:9899`
- Exposed via Tailscale Serve on `https://dev-vps.tail0fe19b.ts.net` (port 443)

ACL starter policy is provided at `docs/tailscale-acl-snippet.json`.

## Renovate

`renovate.json` is configured for weekly flake input updates (no automerge).
