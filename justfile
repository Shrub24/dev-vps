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
bootstrap_key_mode := env_var_or_default("BOOTSTRAP_KEY_MODE", "live")
bootstrap_host_public_key := env_var_or_default("BOOTSTRAP_HOST_PUBLIC_KEY", "")
bootstrap_host_age_recipient := env_var_or_default("BOOTSTRAP_HOST_AGE_RECIPIENT", "")

do_target_host := env_var_or_default("DO_TARGET_HOST", "do-admin-1")
do_bootstrap_user := env_var_or_default("DO_BOOTSTRAP_USER", "root")

default:
  @just --list

help:
  @just --list

check:
  just deploy-check
  just build

ping host=target_host:
  HOST="{{host}}"; HOST="${HOST#host=}"; ping -c 3 "$HOST"

ssh host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" || true

ssh-root host=target_host:
  HOST="{{host}}"; HOST="${HOST#host=}"; ssh "root@$HOST" || true

deploy host rollback="true":
  HOST="{{host}}"; ROLLBACK="{{rollback}}"; HOST="${HOST#host=}"; ROLLBACK="${ROLLBACK#rollback=}"; if [[ -z "$HOST" ]]; then echo "Error: host is required (use host=<deploy-node>)"; exit 1; fi; ARGS=(--skip-checks); if [[ "$ROLLBACK" == "false" ]]; then ARGS+=(--auto-rollback false); fi; nix run .#deploy-rs -- "${ARGS[@]}" ".#$HOST"

deploy-activate host:
  HOST="{{host}}"; HOST="${HOST#host=}"; if [[ -z "$HOST" ]]; then echo "Error: host is required (use host=<deploy-node>)"; exit 1; fi; nix run .#deploy-rs -- --skip-checks --dry-activate ".#$HOST"

deploy-check:
  nix flake check --no-build --no-write-lock-file path:.

# Legacy alias; deploy-rs is the primary deployment path.
redeploy host rollback="true":
  HOST="{{host}}"; ROLLBACK="{{rollback}}"; HOST="${HOST#host=}"; ROLLBACK="${ROLLBACK#rollback=}"; just deploy "$HOST" "$ROLLBACK"

deploy-no-rollback host:
  HOST="{{host}}"; HOST="${HOST#host=}"; just deploy "$HOST" "false"

redeploy-no-rollback host:
  HOST="{{host}}"; HOST="${HOST#host=}"; just redeploy "$HOST" "false"

breakglass-baseline host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" "set -euo pipefail; echo 'Break-glass baseline capture for $USER@$HOST'; hostnamectl; echo; echo 'System profile target:'; readlink -f /nix/var/nix/profiles/system; echo; echo 'System generations (record the generation marked current as the known-good generation):'; sudo nix-env -p /nix/var/nix/profiles/system --list-generations"

derive-host-age host=target_host port="22" key_alias="host_generic_age" sops_file=".sops.yaml" update="false":
  HOST="{{host}}"; PORT="{{port}}"; KEY_ALIAS="{{key_alias}}"; SOPS_FILE="{{sops_file}}"; UPDATE="{{update}}"; HOST="${HOST#host=}"; PORT="${PORT#port=}"; KEY_ALIAS="${KEY_ALIAS#key_alias=}"; SOPS_FILE="${SOPS_FILE#sops_file=}"; UPDATE="${UPDATE#update=}"; KEY_LINE="$(ssh-keyscan -p "$PORT" -t ed25519 "$HOST" 2>/dev/null | awk '/ssh-ed25519/ {print $0; exit}')"; if [[ -z "$KEY_LINE" ]]; then echo "Error: unable to retrieve ed25519 host key from $HOST:$PORT"; exit 1; fi; AGE_RECIPIENT="$(printf '%s\n' "$KEY_LINE" | nix shell nixpkgs#ssh-to-age --command ssh-to-age)"; if [[ "$UPDATE" == "true" ]]; then if rg --quiet "^\s*-\s*&${KEY_ALIAS}\s+age1" "$SOPS_FILE"; then python3 -c "import re, sys; path, alias, recipient = sys.argv[1:4]; text = open(path, 'r', encoding='utf-8').read(); pattern = rf'^(\\s*-\\s*&{re.escape(alias)}\\s+)age1[0-9a-z]+\\s*$'; new, count = re.subn(pattern, rf'\\1{recipient}', text, count=1, flags=re.MULTILINE); if count != 1: raise SystemExit(f'Error: could not update anchor &{alias} in {path}'); open(path, 'w', encoding='utf-8').write(new)" "$SOPS_FILE" "$KEY_ALIAS" "$AGE_RECIPIENT"; else python3 -c "import sys; path, alias, recipient = sys.argv[1:4]; lines = open(path, 'r', encoding='utf-8').read().splitlines(); idx = next((i for i, line in enumerate(lines) if line.strip() == 'keys:'), None); if idx is None: raise SystemExit(f'Error: keys: section not found in {path}'); lines.insert(idx + 1, f'  - &{alias} {recipient}'); open(path, 'w', encoding='utf-8').write('\\n'.join(lines) + '\\n')" "$SOPS_FILE" "$KEY_ALIAS" "$AGE_RECIPIENT"; fi; echo "Updated ${SOPS_FILE} anchor &${KEY_ALIAS} => ${AGE_RECIPIENT}"; else echo "${AGE_RECIPIENT}"; echo "Preview only. Re-run with update=true to write to ${SOPS_FILE} anchor &${KEY_ALIAS}."; fi

derive-host-age-from-key ssh_pubkey key_alias="host_generic_age" sops_file=".sops.yaml" update="false":
  SSH_PUBKEY="{{ssh_pubkey}}"; KEY_ALIAS="{{key_alias}}"; SOPS_FILE="{{sops_file}}"; UPDATE="{{update}}"; KEY_ALIAS="${KEY_ALIAS#key_alias=}"; SOPS_FILE="${SOPS_FILE#sops_file=}"; UPDATE="${UPDATE#update=}"; AGE_RECIPIENT="$(printf '%s\n' "$SSH_PUBKEY" | nix shell nixpkgs#ssh-to-age --command ssh-to-age)"; if [[ "$UPDATE" == "true" ]]; then if rg --quiet "^\s*-\s*&${KEY_ALIAS}\s+age1" "$SOPS_FILE"; then python3 -c "import re, sys; path, alias, recipient = sys.argv[1:4]; text = open(path, 'r', encoding='utf-8').read(); pattern = rf'^(\\s*-\\s*&{re.escape(alias)}\\s+)age1[0-9a-z]+\\s*$'; new, count = re.subn(pattern, rf'\\1{recipient}', text, count=1, flags=re.MULTILINE); if count != 1: raise SystemExit(f'Error: could not update anchor &{alias} in {path}'); open(path, 'w', encoding='utf-8').write(new)" "$SOPS_FILE" "$KEY_ALIAS" "$AGE_RECIPIENT"; else python3 -c "import sys; path, alias, recipient = sys.argv[1:4]; lines = open(path, 'r', encoding='utf-8').read().splitlines(); idx = next((i for i, line in enumerate(lines) if line.strip() == 'keys:'), None); if idx is None: raise SystemExit(f'Error: keys: section not found in {path}'); lines.insert(idx + 1, f'  - &{alias} {recipient}'); open(path, 'w', encoding='utf-8').write('\\n'.join(lines) + '\\n')" "$SOPS_FILE" "$KEY_ALIAS" "$AGE_RECIPIENT"; fi; echo "Updated ${SOPS_FILE} anchor &${KEY_ALIAS} => ${AGE_RECIPIENT}"; else echo "${AGE_RECIPIENT}"; echo "Preview only. Re-run with update=true to write to ${SOPS_FILE} anchor &${KEY_ALIAS}."; fi

bootstrap-do target=do_target_host user=do_bootstrap_user:
  TARGET="{{target}}"; USER="{{user}}"; TARGET="${TARGET#target=}"; USER="${USER#user=}"; just bootstrap target="$TARGET" user="$USER" flake="path:.#do-admin-1" host_config="hosts/do-admin-1/bootstrap-config.nix"

bootstrap-preflight host:
  HOST="{{host}}"; HOST="${HOST#host=}"; if [[ -z "$HOST" ]]; then echo "Error: host is required (use host=<nixosConfiguration>)"; exit 1; fi; nix eval --no-write-lock-file --apply 'cfg: if cfg.services.openssh.enable then true else throw "openssh is disabled"' "path:.#nixosConfigurations.${HOST}.config" >/dev/null; nix eval --no-write-lock-file --apply 'cfg: let ports = cfg.networking.firewall.allowedTCPPorts or [ ]; in if builtins.elem 22 ports then true else throw "firewall does not allow tcp/22"' "path:.#nixosConfigurations.${HOST}.config" >/dev/null; nix eval --no-write-lock-file --apply 'cfg: let devKeys = cfg.users.users.dev.openssh.authorizedKeys.keys or [ ]; rootKeys = cfg.users.users.root.openssh.authorizedKeys.keys or [ ]; in if (builtins.length devKeys > 0) && (builtins.length rootKeys > 0) then true else throw "missing declarative dev/root SSH keys"' "path:.#nixosConfigurations.${HOST}.config" >/dev/null; echo "bootstrap-preflight PASS: ${HOST} (openssh enabled, tcp/22 allowed, declarative dev/root SSH keys present)"

bootstrap target=bootstrap_target user=bootstrap_user flake=bootstrap_flake host_config=bootstrap_host_config extra_files=bootstrap_extra_files hardware_config_generator=bootstrap_hardware_config_generator hardware_config_path=bootstrap_hardware_config_path skip_hardware_config=bootstrap_skip_hardware_config key_mode=bootstrap_key_mode host_public_key=bootstrap_host_public_key host_age_recipient=bootstrap_host_age_recipient:
  CMD=(./deploy.sh --host-config "{{host_config}}" --target "{{target}}" --bootstrap-user "{{user}}" --flake "{{flake}}" --bootstrap-key-mode "{{key_mode}}"); if [[ -n "{{extra_files}}" ]]; then CMD+=(--extra-files "{{extra_files}}"); fi; if [[ -n "{{hardware_config_generator}}" ]]; then CMD+=(--hardware-config-generator "{{hardware_config_generator}}"); fi; if [[ -n "{{hardware_config_path}}" ]]; then CMD+=(--hardware-config-path "{{hardware_config_path}}"); fi; if [[ -n "{{host_public_key}}" ]]; then CMD+=(--host-public-key "{{host_public_key}}"); fi; if [[ -n "{{host_age_recipient}}" ]]; then CMD+=(--host-age-recipient "{{host_age_recipient}}"); fi; if [[ "{{skip_hardware_config}}" == "true" ]]; then CMD+=(--skip-hardware-config); fi; "${CMD[@]}"

flake-check:
  just deploy-check

verify-oci-contract:
  nix flake check --no-build --no-write-lock-file path:.
  nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.networking.hostName
  nix eval path:.#nixosConfigurations.oci-melb-1.config.services.tailscale.enable
  nix eval path:.#nixosConfigurations.oci-melb-1.config.services.syncthing.enable
  nix eval path:.#nixosConfigurations.oci-melb-1.config.services.navidrome.enable

verify-do-admin-contract:
  nix flake check --no-build --no-write-lock-file path:.
  nix eval --raw path:.#nixosConfigurations.do-admin-1.config.networking.hostName
  nix eval path:.#nixosConfigurations.do-admin-1.config.services.tailscale.enable

verify-phase-03:
  bash tests/phase-03-bootstrap-contract.sh
  bash tests/phase-03-access-contract.sh
  bash tests/phase-03-operations-contract.sh
  bash tests/phase-do-admin-contract.sh
  just verify-oci-contract
  just verify-do-admin-contract

verify-phase-04:
  bash tests/phase-04-syncthing-contract.sh
  bash tests/phase-04-service-flow-contract.sh
  just verify-oci-contract

# verify-phase-04.1:
verify-phase-04-1:
  just verify-phase-04
  bash tests/phase-04.1-beets-contract.sh

# verify-phase-04.2:
verify-phase-04-2:
  just verify-phase-04
  bash tests/phase-04.2-beets-promotion-contract.sh

devshell-check:
  nix develop --command just --list >/dev/null

build:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel

build-do-admin:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.do-admin-1.config.system.build.toplevel

vm-build:
  nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.vm

logs host=target_host user=target_user unit="tailscaled" lines="200":
  HOST="{{host}}"; USER="{{user}}"; UNIT="{{unit}}"; LINES="{{lines}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; UNIT="${UNIT#unit=}"; LINES="${LINES#lines=}"; ssh "$USER@$HOST" "sudo journalctl -u $UNIT -n $LINES --no-pager"

status host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" "hostnamectl; echo; sudo systemctl --no-pager --full status tailscaled"

tailscale-status host=target_host user=target_user:
  HOST="{{host}}"; USER="{{user}}"; HOST="${HOST#host=}"; USER="${USER#user=}"; ssh "$USER@$HOST" "sudo tailscale status"

deploy-rs target="path:.#oci-melb-1":
  TARGET="{{target}}"; TARGET="${TARGET#target=}"; nix run github:serokell/deploy-rs -- "$TARGET"

deploy-rs-no-rollback target="path:.#oci-melb-1":
  TARGET="{{target}}"; TARGET="${TARGET#target=}"; nix run github:serokell/deploy-rs -- "$TARGET" --rollback-succeeded false --magic-rollback false
