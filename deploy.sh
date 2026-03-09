#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <droplet-ip> [disk-device]"
  exit 1
fi

TARGET_IP="$1"
DISK_DEVICE="${2:-/dev/vda}"

nix run github:nix-community/nixos-anywhere -- \
  --flake .#dev-vps \
  --disk main "$DISK_DEVICE" \
  "root@${TARGET_IP}"
