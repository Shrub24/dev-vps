set shell := ["bash", "-euo", "pipefail", "-c"]

target_host := env_var_or_default("TARGET_HOST", "oci-melb-1")
target_user := env_var_or_default("TARGET_USER", "dev")

default:
  @just --list

help:
  @just --list

check:
  just flake-check
  just build

ping:
  ping -c 3 {{target_host}}

ssh:
  ssh {{target_user}}@{{target_host}} || true

ssh-root:
  ssh root@{{target_host}} || true

redeploy:
  nix run nixpkgs#nixos-rebuild -- switch --flake path:.#oci-melb-1 --sudo --target-host {{target_user}}@{{target_host}} --build-host {{target_user}}@{{target_host}}

flake-check:
  nix flake check --no-build --no-write-lock-file path:.

devshell-check:
  nix develop --command just --list >/dev/null

build:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel

vm-build:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.vm

logs unit="tailscaled" lines="200":
  ssh {{target_user}}@{{target_host}} "sudo journalctl -u {{unit}} -n {{lines}} --no-pager"

status:
  ssh {{target_user}}@{{target_host}} "hostnamectl; echo; sudo systemctl --no-pager --full status tailscaled"

tailscale-status:
  ssh {{target_user}}@{{target_host}} "sudo tailscale status"
