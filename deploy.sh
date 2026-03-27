#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_CONFIG="${SCRIPT_DIR}/hosts/oci-melb-1/bootstrap-config.nix"
TARGET_HOST=""
BOOTSTRAP_USER=""
FLAKE_TARGET=""
EXTRA_FILES=""

usage() {
	cat <<EOF
Usage: $0 [--host-config <path>] [--target <host-or-ip>] [--bootstrap-user <user>] [--flake <flake-ref>] [--extra-files <path>]

Defaults are loaded from: hosts/oci-melb-1/bootstrap-config.nix
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--host-config)
		if [[ $# -lt 2 ]]; then
			echo "Error: --host-config requires a value"
			exit 1
		fi
		BOOTSTRAP_CONFIG="$2"
		shift 2
		;;
	--target)
		if [[ $# -lt 2 ]]; then
			echo "Error: --target requires a value"
			exit 1
		fi
		TARGET_HOST="$2"
		shift 2
		;;
	--bootstrap-user)
		if [[ $# -lt 2 ]]; then
			echo "Error: --bootstrap-user requires a value"
			exit 1
		fi
		BOOTSTRAP_USER="$2"
		shift 2
		;;
	--flake)
		if [[ $# -lt 2 ]]; then
			echo "Error: --flake requires a value"
			exit 1
		fi
		FLAKE_TARGET="$2"
		shift 2
		;;
	--extra-files)
		if [[ $# -lt 2 ]]; then
			echo "Error: --extra-files requires a value"
			exit 1
		fi
		EXTRA_FILES="$2"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Error: unknown argument: $1"
		usage
		exit 1
		;;
	esac
done

normalize_prefixed_value() {
	local key="$1"
	local value="$2"
	if [[ "$value" == "${key}="* ]]; then
		printf '%s' "${value#${key}=}"
	else
		printf '%s' "$value"
	fi
}

TARGET_HOST="$(normalize_prefixed_value target "$TARGET_HOST")"
BOOTSTRAP_USER="$(normalize_prefixed_value user "$BOOTSTRAP_USER")"
FLAKE_TARGET="$(normalize_prefixed_value flake "$FLAKE_TARGET")"
BOOTSTRAP_CONFIG="$(normalize_prefixed_value host_config "$BOOTSTRAP_CONFIG")"
EXTRA_FILES="$(normalize_prefixed_value extra_files "$EXTRA_FILES")"

if [[ ! -f "$BOOTSTRAP_CONFIG" ]]; then
	echo "Error: bootstrap config not found: $BOOTSTRAP_CONFIG"
	exit 1
fi

if [[ -z "$TARGET_HOST" ]]; then
	TARGET_HOST="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" hostName)"
fi

if [[ -z "$BOOTSTRAP_USER" ]]; then
	BOOTSTRAP_USER="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" bootstrapUser)"
fi

if [[ -z "$FLAKE_TARGET" ]]; then
	FLAKE_TARGET="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" flake)"
fi

CMD=(
	nix run github:nix-community/nixos-anywhere --
	--flake "$FLAKE_TARGET"
	--build-on remote
	--target-host "${BOOTSTRAP_USER}@${TARGET_HOST}"
)

if [[ -n "$EXTRA_FILES" ]]; then
	CMD+=(--extra-files "$EXTRA_FILES")
fi

"${CMD[@]}"
