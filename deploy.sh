#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <droplet-ip> [extra-files]"
	exit 1
fi

TARGET_IP="$1"
EXTRA_FILES="${2:-}"

CMD=(
	nix run github:nix-community/nixos-anywhere --
	--flake "path:.#dev-vps"
	--target-host "root@${TARGET_IP}"
)

if [[ -n "$EXTRA_FILES" ]]; then
	CMD+=(--extra-files "$EXTRA_FILES")
fi

"${CMD[@]}"
