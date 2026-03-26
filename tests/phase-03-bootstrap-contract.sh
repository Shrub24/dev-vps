#!/usr/bin/env bash
set -euo pipefail

DEPLOY_FILE="deploy.sh"
HOST_FILE="hosts/oci-melb-1/default.nix"
DISKO_FILE="modules/storage/disko-root.nix"

rg --fixed-strings --quiet 'nix run github:nix-community/nixos-anywhere --' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--flake "path:.#oci-melb-1"' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--build-on-remote' "$DEPLOY_FILE"
rg --fixed-strings --quiet -- '--target-host "root@${TARGET_HOST}"' "$DEPLOY_FILE"

rg --fixed-strings --quiet '../../modules/storage/disko-root.nix' "$HOST_FILE"

rg --fixed-strings --quiet 'mountpoint = "/"' "$DISKO_FILE"
rg --fixed-strings --quiet 'mountpoint = "/srv/data"' "$DISKO_FILE"
rg --fixed-strings --quiet 'extraArgs = [ "-L" "rootfs" ]' "$DISKO_FILE"
rg --fixed-strings --quiet 'extraArgs = [ "-L" "srv-data" ]' "$DISKO_FILE"
