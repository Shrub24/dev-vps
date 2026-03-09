# dev-vps

Reproducible NixOS VPS for mobile OpenCode sessions via CodeNomad + Tailscale.

## Layout

- `flake.nix`: flake entrypoint (`.#dev-vps`)
- `nixos/configuration.nix`: host config, services, users, firewall
- `nixos/disko-config.nix`: GPT + BIOS+UEFI partitioning
- `home/dev.nix`: Home Manager profile for user `dev`
- `pkgs/codenomad/package.nix`: pinned `buildNpmPackage` for CodeNomad
- `pkgs/opencode/package.nix`: pinned `buildNpmPackage` for OpenCode
- `pkgs/repo-sync/`: repo sync utility for code + private agent state
- `secrets/secrets.yaml`: encrypted runtime secrets (sops)
- `deploy.sh`: nixos-anywhere helper

## Deploy

```bash
./deploy.sh <DROPLET_IP> [EXTRA_FILES_DIR]
```

Disk target is pinned for DigitalOcean as `/dev/vda` in `flake.nix`.

## Local test

Build full system:

```bash
nix build --no-link path:.#nixosConfigurations.dev-vps.config.system.build.toplevel
```

Build VM artifact:

```bash
nix build --no-link path:.#nixosConfigurations.dev-vps.config.system.build.vm
```

## Dev shell

This repo includes a Nix dev shell for local maintenance commands (`just`, `sops`, `age`, `nixos-anywhere`, `jq`, `yq`).

```bash
direnv allow
```

or:

```bash
nix develop
```

## Home Manager

User-level shell config for `dev` is managed with Home Manager.

- zsh config is deployed from `zshrc/` to `~/.config/zshrc`
- `~/.zshenv` sets `ZDOTDIR=~/.config/zshrc`
- `ZSH_MOBILE` defaults to `1` and can be overridden per session

## Secrets (bootstrap once)

This repo uses `sops-nix`.

1. Generate a VPS age key and store private key at `/var/lib/sops-nix/key.txt`.
2. Add the VPS **public** age key to `.sops.yaml` recipients.
3. Update secret values in `secrets/secrets.yaml` and re-encrypt with `sops`.
4. Redeploy.

Secrets expected:

- `codenomad/env`: env file content (username + password)
- `tailscale/auth_key`: reusable tagged auth key
- `github/token`: GitHub token used by `repo-sync` for private repo HTTPS access

## Tailscale

- Hostname is `dev-vps`
- Tag advertised: `tag:dev-vps`
- CodeNomad binds localhost on `127.0.0.1:9899`
- Exposed via Tailscale Serve on `https://dev-vps.tail0fe19b.ts.net` (port 443)

ACL starter policy is provided at `docs/tailscale-acl-snippet.json`.

## Renovate

`renovate.json` is configured for weekly flake input updates (no automerge).

## Repo Sync

`repo-sync` keeps selected repos and per-repo private state in sync.

- code repos live under `/home/dev/workspaces/github/<owner>/<repo>`
- private state repo lives at `/home/dev/state` (`Shrub24/agent-state`)
- per-repo state lives at `/home/dev/state/repos/github/<owner>/<repo>`

### Config file

`/home/dev/state/config/repos.yaml` controls managed repos and arbitrary mappings.

Example:

```yaml
repos:
  - name: Shrub24/dev-vps
    mappings:
      - from: state:.opencode
        to: repo:.opencode
        untracked: true
      - from: state:personal/flake.nix
        to: repo:flake.nix
        untracked: true
```

Mapping rules:

- `from: state:<path>` is relative to `/home/dev/state/repos/github/<owner>/<repo>/`
- `to: repo:<path>` is relative to the code repo root
- mappings are symlinks
- `untracked: true` adds the target to `.git/info/exclude` in the code repo

### Commands

- `repo-sync bootstrap` - clone/init state repo and config
- `repo-sync add Shrub24/repo` - add a managed repo (local commit to state repo)
- `repo-sync add Shrub24/repo --push` - add and push state repo changes
- `repo-sync sync` - pull state config and sync all managed repos
- `repo-sync scan` - discover local repos under workspaces and add to YAML
- `repo-sync state pull` - pull latest state repo
- `repo-sync state commit` - commit pending state changes
- `repo-sync state push` - push state repo commits

Each managed repo gets a local `post-commit` hook that runs `repo-sync state commit --repo <owner/repo> --code-sha <sha>`. It commits state locally only (no push unless explicit).
