#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_CONFIG="${SCRIPT_DIR}/hosts/oci-melb-1/bootstrap-config.nix"
BOOTSTRAP_KEY_MODE="live"
BOOTSTRAP_HOST_PUBLIC_KEY=""
BOOTSTRAP_HOST_AGE_RECIPIENT=""
TARGET_HOST=""
BOOTSTRAP_USER=""
FLAKE_TARGET=""
EXTRA_FILES=""
HARDWARE_CONFIG_GENERATOR=""
HARDWARE_CONFIG_PATH=""
SKIP_HARDWARE_CONFIG="false"

usage() {
	cat <<EOF
Usage: $0 [--host-config <path>] [--target <host-or-ip>] [--bootstrap-user <user>] [--flake <flake-ref>] [--extra-files <path>] [--hardware-config-generator <name>] [--hardware-config-path <path>] [--bootstrap-key-mode <live|injected>] [--host-public-key <ssh-ed25519...>] [--host-age-recipient <age1...>] [--skip-hardware-config]

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
	--hardware-config-generator)
		if [[ $# -lt 2 ]]; then
			echo "Error: --hardware-config-generator requires a value"
			exit 1
		fi
		HARDWARE_CONFIG_GENERATOR="$2"
		shift 2
		;;
	--hardware-config-path)
		if [[ $# -lt 2 ]]; then
			echo "Error: --hardware-config-path requires a value"
			exit 1
		fi
		HARDWARE_CONFIG_PATH="$2"
		shift 2
		;;
	--bootstrap-key-mode)
		if [[ $# -lt 2 ]]; then
			echo "Error: --bootstrap-key-mode requires a value"
			exit 1
		fi
		BOOTSTRAP_KEY_MODE="$2"
		shift 2
		;;
	--host-public-key)
		if [[ $# -lt 2 ]]; then
			echo "Error: --host-public-key requires a value"
			exit 1
		fi
		BOOTSTRAP_HOST_PUBLIC_KEY="$2"
		shift 2
		;;
	--host-age-recipient)
		if [[ $# -lt 2 ]]; then
			echo "Error: --host-age-recipient requires a value"
			exit 1
		fi
		BOOTSTRAP_HOST_AGE_RECIPIENT="$2"
		shift 2
		;;
	--skip-hardware-config)
		SKIP_HARDWARE_CONFIG="true"
		shift
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

derive_host_age_recipient() {
	local mode="$1"
	local host="$2"
	local ssh_port="${3:-22}"
	local ssh_pubkey="$4"
	local age_recipient="$5"

	if [[ -n "$age_recipient" ]]; then
		printf '%s' "$age_recipient"
		return
	fi

	if [[ "$mode" == "injected" ]]; then
		if [[ -z "$ssh_pubkey" ]]; then
			echo "Error: --host-public-key is required when --bootstrap-key-mode=injected"
			exit 1
		fi
		printf '%s\n' "$ssh_pubkey" | nix shell nixpkgs#ssh-to-age --command ssh-to-age
		return
	fi

	local key_line
	key_line="$(ssh-keyscan -p "$ssh_port" -t ed25519 "$host" 2>/dev/null | awk '/ssh-ed25519/ {print $0; exit}')"
	if [[ -z "$key_line" ]]; then
		echo "Error: unable to retrieve ed25519 host key from ${host}:${ssh_port}"
		exit 1
	fi

	printf '%s\n' "$key_line" | nix shell nixpkgs#ssh-to-age --command ssh-to-age
}

eval_bootstrap_attr_with_fallback() {
	local attr="$1"
	local fallback="$2"
	local value=""

	if value="$(nix eval --raw --file "$BOOTSTRAP_CONFIG" "$attr" 2>/dev/null)"; then
		printf '%s' "$value"
	else
		printf '%s' "$fallback"
	fi
}

TARGET_HOST="$(normalize_prefixed_value target "$TARGET_HOST")"
BOOTSTRAP_USER="$(normalize_prefixed_value user "$BOOTSTRAP_USER")"
FLAKE_TARGET="$(normalize_prefixed_value flake "$FLAKE_TARGET")"
BOOTSTRAP_CONFIG="$(normalize_prefixed_value host_config "$BOOTSTRAP_CONFIG")"
EXTRA_FILES="$(normalize_prefixed_value extra_files "$EXTRA_FILES")"
HARDWARE_CONFIG_GENERATOR="$(normalize_prefixed_value hardware_config_generator "$HARDWARE_CONFIG_GENERATOR")"
HARDWARE_CONFIG_PATH="$(normalize_prefixed_value hardware_config_path "$HARDWARE_CONFIG_PATH")"
BOOTSTRAP_KEY_MODE="$(normalize_prefixed_value bootstrap_key_mode "$BOOTSTRAP_KEY_MODE")"
BOOTSTRAP_HOST_PUBLIC_KEY="$(normalize_prefixed_value host_public_key "$BOOTSTRAP_HOST_PUBLIC_KEY")"
BOOTSTRAP_HOST_AGE_RECIPIENT="$(normalize_prefixed_value host_age_recipient "$BOOTSTRAP_HOST_AGE_RECIPIENT")"

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

if [[ -z "$HARDWARE_CONFIG_GENERATOR" ]]; then
	HARDWARE_CONFIG_GENERATOR="$(eval_bootstrap_attr_with_fallback hardwareConfigGenerator "nixos-generate-config")"
fi

if [[ -z "$HARDWARE_CONFIG_PATH" ]]; then
	HARDWARE_CONFIG_PATH="$(eval_bootstrap_attr_with_fallback hardwareConfigPath "hosts/oci-melb-1/hardware-configuration.nix")"
fi

DERIVED_HOST_AGE_RECIPIENT="$(derive_host_age_recipient "$BOOTSTRAP_KEY_MODE" "$TARGET_HOST" "22" "$BOOTSTRAP_HOST_PUBLIC_KEY" "$BOOTSTRAP_HOST_AGE_RECIPIENT")"
echo "Derived host age recipient (${BOOTSTRAP_KEY_MODE}): ${DERIVED_HOST_AGE_RECIPIENT}"

CMD=(
	nix run github:nix-community/nixos-anywhere --
	--flake "$FLAKE_TARGET"
	--build-on remote
	--target-host "${BOOTSTRAP_USER}@${TARGET_HOST}"
)

if [[ -n "$EXTRA_FILES" ]]; then
	CMD+=(--extra-files "$EXTRA_FILES")
fi

if [[ "$SKIP_HARDWARE_CONFIG" != "true" ]] && [[ -n "$HARDWARE_CONFIG_GENERATOR" ]] && [[ -n "$HARDWARE_CONFIG_PATH" ]]; then
	CMD+=(--generate-hardware-config "$HARDWARE_CONFIG_GENERATOR" "$HARDWARE_CONFIG_PATH")
fi

"${CMD[@]}"
