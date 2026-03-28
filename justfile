set shell := ["bash", "-euo", "pipefail", "-c"]

target_host := env_var_or_default("TARGET_HOST", "oci-melb-1")
target_user := env_var_or_default("TARGET_USER", "dev")
bootstrap_target := env_var_or_default("BOOTSTRAP_TARGET", target_host)
bootstrap_user := env_var_or_default("BOOTSTRAP_USER", "ubuntu")
bootstrap_flake := env_var_or_default("BOOTSTRAP_FLAKE", "path:.#oci-melb-1")
bootstrap_host_config := env_var_or_default("BOOTSTRAP_HOST_CONFIG", "hosts/oci-melb-1/bootstrap-config.nix")
bootstrap_extra_files := env_var_or_default("BOOTSTRAP_EXTRA_FILES", "")
bootstrap_hardware_config_generator := env_var_or_default("BOOTSTRAP_HARDWARE_CONFIG_GENERATOR", "")
bootstrap_hardware_config_path := env_var_or_default("BOOTSTRAP_HARDWARE_CONFIG_PATH", "")
bootstrap_skip_hardware_config := env_var_or_default("BOOTSTRAP_SKIP_HARDWARE_CONFIG", "false")

default:
  @just --list

help:
  @just --list

check:
  just flake-check
  just build

ping host=target_host:
  HOST="{{host}}"; HOST="${HOST#host=}"; ping -c 3 "$HOST"

ssh host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" || true

ssh-root host=target_host:
  HOST="{{host}}"; HOST="${HOST#host=}"; ssh "root@$HOST" || true

redeploy host=target_host user=target_user flake="path:.#oci-melb-1":
  HOST="{{host}}"; USER="{{user}}"; FLAKE="{{flake}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; FLAKE="${FLAKE#flake=}"; nix run nixpkgs#nixos-rebuild -- switch --flake "$FLAKE" --sudo --target-host "$USER@$HOST" --build-host "$USER@$HOST"

breakglass-baseline host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" "set -euo pipefail; echo 'Break-glass baseline capture for $USER@$HOST'; hostnamectl; echo; echo 'System profile target:'; readlink -f /nix/var/nix/profiles/system; echo; echo 'System generations (record the generation marked current as the known-good generation):'; sudo nix-env -p /nix/var/nix/profiles/system --list-generations"

bootstrap target=bootstrap_target user=bootstrap_user flake=bootstrap_flake host_config=bootstrap_host_config extra_files=bootstrap_extra_files hardware_config_generator=bootstrap_hardware_config_generator hardware_config_path=bootstrap_hardware_config_path skip_hardware_config=bootstrap_skip_hardware_config:
  CMD=(./deploy.sh --host-config "{{host_config}}" --target "{{target}}" --bootstrap-user "{{user}}" --flake "{{flake}}"); if [[ -n "{{extra_files}}" ]]; then CMD+=(--extra-files "{{extra_files}}"); fi; if [[ -n "{{hardware_config_generator}}" ]]; then CMD+=(--hardware-config-generator "{{hardware_config_generator}}"); fi; if [[ -n "{{hardware_config_path}}" ]]; then CMD+=(--hardware-config-path "{{hardware_config_path}}"); fi; if [[ "{{skip_hardware_config}}" == "true" ]]; then CMD+=(--skip-hardware-config); fi; "${CMD[@]}"

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

logs host=target_host user=target_user unit="tailscaled" lines="200":
  HOST="{{host}}"; USER="{{user}}"; UNIT="{{unit}}"; LINES="{{lines}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; UNIT="${UNIT#unit=}"; LINES="${LINES#lines=}"; ssh "$USER@$HOST" "sudo journalctl -u $UNIT -n $LINES --no-pager"

status host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" "hostnamectl; echo; sudo systemctl --no-pager --full status tailscaled"

tailscale-status host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" "sudo tailscale status"
