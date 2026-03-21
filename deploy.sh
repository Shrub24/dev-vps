#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <target-host> [extra-files]"
	exit 1
fi

TARGET_HOST="$1"
EXTRA_FILES="${2:-}"

CMD=(
	nix run github:nix-community/nixos-anywhere --
	--flake "path:.#oci-melb-1"
	--build-on-remote
	--target-host "root@${TARGET_HOST}"
)

if [[ -n "$EXTRA_FILES" ]]; then
	CMD+=(--extra-files "$EXTRA_FILES")
fi

"${CMD[@]}"
