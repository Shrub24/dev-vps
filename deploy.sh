#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <droplet-ip> [disk-device]"
  exit 1
fi

TARGET_IP="$1"

nix run github:nix-community/nixos-anywhere -- \
  --flake .#dev-vps \
  --extra-files "$tmp" \
  --target-host "root@${TARGET_IP}"
