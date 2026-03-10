set shell := ["bash", "-euo", "pipefail", "-c"]

ip := env_var_or_default("DROPLET_IP", "138.68.162.231")
user := env_var_or_default("DROPLET_USER", "dev")

default:
  @just --list

help:
  @just --list

check:
  just flake-check
  just build

ping:
  ping -c 3 {{ip}}

ssh:
  ssh {{user}}@{{ip}} || true

ssh-root:
  ssh root@{{ip}} || true

redeploy:
  nix run nixpkgs#nixos-rebuild -- switch --flake path:.#dev-vps --sudo --target-host {{user}}@{{ip}} --build-host {{user}}@{{ip}}

flake-check:
  nix flake check --no-build --no-write-lock-file path:.

build:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.dev-vps.config.system.build.toplevel

vm-build:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.dev-vps.config.system.build.vm

logs unit="codenomad" lines="200":
  ssh {{user}}@{{ip}} "sudo journalctl -u {{unit}} -n {{lines}} --no-pager"

status:
  ssh {{user}}@{{ip}} "hostnamectl; echo; sudo systemctl --no-pager --full status tailscaled codenomad tailscale-serve-codenomad"

tailscale-status:
  ssh {{user}}@{{ip}} "sudo tailscale status; echo; sudo tailscale serve status"

hm-status:
  ssh {{user}}@{{ip}} "systemctl status home-manager-dev --no-pager || true"

install-repo-sync:
  nix profile install --accept-flake-config path:.#repo-sync

upgrade-repo-sync:
  nix profile upgrade repo-sync

reinstall-repo-sync:
  nix profile remove repo-sync || true
  nix profile install --accept-flake-config path:.#repo-sync
