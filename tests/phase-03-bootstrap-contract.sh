#!/usr/bin/env bash
set -euo pipefail

DEPLOY_FILE="deploy.sh"
BOOTSTRAP_CONFIG_FILE="hosts/oci-melb-1/bootstrap-config.nix"
HOST_FILE="hosts/oci-melb-1/default.nix"
DISKO_FILE="modules/storage/disko-root.nix"
JUSTFILE="justfile"
OCI_PROVIDER_FILE="modules/providers/oci/default.nix"

rg --fixed-strings --quiet 'nix run github:nix-community/nixos-anywhere --' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- 'BOOTSTRAP_CONFIG="${SCRIPT_DIR}/hosts/oci-melb-1/bootstrap-config.nix"' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--host-config <path>' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- 'TARGET_HOST="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" hostName)"' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- 'BOOTSTRAP_USER="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" bootstrapUser)"' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- 'FLAKE_TARGET="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" flake)"' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--flake "$FLAKE_TARGET"' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--build-on-remote' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--target-host "${BOOTSTRAP_USER}@${TARGET_HOST}"' "$DEPLOY_FILE"
! rg --fixed-strings --quiet 'root@${TARGET_HOST}' "$DEPLOY_FILE"

rg --fixed-strings --quiet 'bootstrapUser = "ubuntu";' "$BOOTSTRAP_CONFIG_FILE"
rg --fixed-strings --quiet 'bootstrapDisk = "/dev/sda";' "$BOOTSTRAP_CONFIG_FILE"
rg --fixed-strings --quiet 'flake = "path:.#oci-melb-1";' "$BOOTSTRAP_CONFIG_FILE"
rg --fixed-strings --quiet 'bootstrapConfig = import ../../../hosts/oci-melb-1/bootstrap-config.nix;' "$OCI_PROVIDER_FILE"
rg --fixed-strings --quiet 'disko.devices.disk.main.device = lib.mkDefault bootstrapConfig.bootstrapDisk;' "$OCI_PROVIDER_FILE"
rg --fixed-strings --quiet 'boot.loader.grub.devices = [ bootstrapConfig.bootstrapDisk ];' "$OCI_PROVIDER_FILE"

rg --fixed-strings --quiet 'bootstrap target=bootstrap_target user=bootstrap_user flake=bootstrap_flake host_config=bootstrap_host_config extra_files=bootstrap_extra_files:' "$JUSTFILE"
rg --fixed-strings --quiet './deploy.sh --host-config "{{host_config}}" --target "{{target}}" --bootstrap-user "{{user}}" --flake "{{flake}}"' "$JUSTFILE"

rg --fixed-strings --quiet '../../modules/storage/disko-root.nix' "$HOST_FILE"

rg --fixed-strings --quiet 'mountpoint = "/"' "$DISKO_FILE"
rg --fixed-strings --quiet 'mountpoint = "/srv/data"' "$DISKO_FILE"
rg --fixed-strings --quiet 'extraArgs = [ "-L" "rootfs" ]' "$DISKO_FILE"
rg --fixed-strings --quiet 'extraArgs = [ "-L" "srv-data" ]' "$DISKO_FILE"
