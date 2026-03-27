set shell := ["bash", "-euo", "pipefail", "-c"]

target_host := env_var_or_default("TARGET_HOST", "oci-melb-1")
target_user := env_var_or_default("TARGET_USER", "dev")
bootstrap_target := env_var_or_default("BOOTSTRAP_TARGET", target_host)
bootstrap_user := env_var_or_default("BOOTSTRAP_USER", "ubuntu")
bootstrap_flake := env_var_or_default("BOOTSTRAP_FLAKE", "path:.#oci-melb-1")
bootstrap_host_config := env_var_or_default("BOOTSTRAP_HOST_CONFIG", "hosts/oci-melb-1/bootstrap-config.nix")
bootstrap_extra_files := env_var_or_default("BOOTSTRAP_EXTRA_FILES", "")

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

bootstrap target=bootstrap_target user=bootstrap_user flake=bootstrap_flake host_config=bootstrap_host_config extra_files=bootstrap_extra_files:
  if [[ -n "{{extra_files}}" ]]; then ./deploy.sh --host-config "{{host_config}}" --target "{{target}}" --bootstrap-user "{{user}}" --flake "{{flake}}" --extra-files "{{extra_files}}"; else ./deploy.sh --host-config "{{host_config}}" --target "{{target}}" --bootstrap-user "{{user}}" --flake "{{flake}}"; fi

flake-check:
  nix flake check --no-build --no-write-lock-file path:.

verify-oci-contract:
  nix flake check --no-build --no-write-lock-file path:.
  nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.networking.hostName
  nix eval path:.#nixosConfigurations.oci-melb-1.config.services.tailscale.enable
  nix eval path:.#nixosConfigurations.oci-melb-1.config.services.syncthing.enable
  nix eval path:.#nixosConfigurations.oci-melb-1.config.services.navidrome.enable

verify-phase-03:
  bash tests/phase-03-bootstrap-contract.sh
  bash tests/phase-03-access-contract.sh
  bash tests/phase-03-operations-contract.sh
  just verify-oci-contract

verify-phase-04:
  bash tests/phase-04-syncthing-contract.sh
  bash tests/phase-04-service-flow-contract.sh
  just verify-oci-contract

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
