# dev-vps

Reproducible NixOS VPS for mobile OpenCode sessions via CodeNomad + Tailscale.

This repo is intentionally split into:

- stable NixOS system config (server reliability)
- unstable local dev shell for repo maintenance
- Home Manager for user shell environment (`dev`)
- private state + repo orchestration via `repo-sync`

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

## Quick start

Use `just` for common operations.

```bash
just help
just redeploy
just status
just tailscale-status
```

Set host/user once if needed:

```bash
export DROPLET_IP=<ip>
export DROPLET_USER=dev
```

Repo-sync env template:

```bash
cp .env.template ~/.config/repo-sync.env
```

Disk target is pinned for DigitalOcean as `/dev/vda` in `flake.nix`.

## Common commands

- `just flake-check` - evaluate flake outputs
- `just build` - build full NixOS system derivation
- `just vm-build` - build local VM artifact
- `just redeploy` - rebuild/switch remote VPS
- `just logs unit=codenomad` - inspect service logs
- `just hm-status` - check Home Manager activation unit
- `just install-repo-sync` - install `repo-sync` locally via nix profile

## Dev shell

This repo includes an unstable maintenance dev shell (`just`, `sops`, `age`, `nixos-anywhere`, `jq`, `yq`, `nixfmt`, `statix`).

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
- entrypoint is `zshrc/.zshrc`, which sources `zshrc/main.zsh`

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

Template files:

- `.env.template` for repo-sync runtime configuration
- `secrets/secrets.template.yaml` as unencrypted secrets reference

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

Intentions:

- keep team/public repos clean (no personal dotfiles committed)
- keep private per-repo agent state in one private repo (`Shrub24/project-state`)
- auto-commit local state changes on project commits (push only when explicit)

- code repos live under `/home/dev/workspaces/github/<owner>/<repo>`
- private state repo lives at `/home/dev/project-state` (`Shrub24/project-state`)
- per-repo state lives at `/home/dev/project-state/repos/github/<owner>/<repo>`

### Config file

`/home/dev/project-state/config/repos.yaml` controls managed repos and arbitrary mappings.

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

- `from: state:<path>` is relative to `/home/dev/project-state/repos/github/<owner>/<repo>/`
- `to: repo:<path>` is relative to the code repo root
- mappings are symlinks
- `untracked` defaults to `true` unless explicitly set to `false`
- if `to` is omitted, it defaults to the same relative path as `from`
- default behavior maps all top-level paths from state repo dir to repo root unless explicitly mapped or ignored
- `ignorePaths` can skip default root mappings for specific paths
- `untracked: true` adds the target to `.git/info/exclude` in the code repo

Extended example:

```yaml
repos:
  - name: Shrub24/dev-vps
    ignorePaths:
      - .direnv
      - private
    mappings:
      - from: state:.opencode
        to: repo:.opencode
      - from: state:personal/flake.nix
        to: repo:flake.nix
        untracked: true
```

### Commands

- `repo-sync bootstrap` - clone/init state repo and config
- `repo-sync init` - initialize or clone `project-state` and config
- `repo-sync add Shrub24/repo` - add a managed repo (local commit to state repo)
- `repo-sync add Shrub24/repo --ignore-path .direnv --ignore-path private` - ignore defaults
- `repo-sync add Shrub24/repo --push` - add and push state repo changes
- `repo-sync sync` - pull state config and sync all managed repos
- `repo-sync scan` - discover local repos under workspaces and add to YAML
- `repo-sync state pull` - pull latest state repo
- `repo-sync state add <path>` - move a repo path into project-state and map it back as symlink
- `repo-sync state commit` - commit pending state changes
- `repo-sync state push` - push state repo commits

Help:

```bash
repo-sync --help
repo-sync add --help
repo-sync state commit --help
```

Completions are installed with the package:

- zsh: `_repo-sync`
- bash: `repo-sync`

Repo-name completion is available for `repo-sync add` and `repo-sync state commit --repo`, sourced from managed YAML + existing local checkouts.

Each managed repo gets a local `post-commit` hook that runs `repo-sync state commit --repo <owner/repo> --code-sha <sha>`. It commits state locally only (no push unless explicit).
