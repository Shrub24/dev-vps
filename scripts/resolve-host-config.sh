#!/usr/bin/env bash
# usage: source scripts/resolve-host-config.sh <host>
# sets: BOOTSTRAP_USER, FLAKE, HOST_CONFIG
set -euo pipefail

HOST="$1"
HOST_CONFIG="hosts/${HOST}/bootstrap-config.nix"

if [[ ! -f "$HOST_CONFIG" ]]; then
  echo "Error: no bootstrap-config.nix found for host '${HOST}'" >&2
  exit 1
fi

# Parse the attrset directly — each key is on its own line as "  key = \"value\";".
BOOTSTRAP_USER="$(grep '^  bootstrapUser' "$HOST_CONFIG" | sed 's/.*= *"\([^"]*\)".*/\1/')"
FLAKE="$(grep '^  flake' "$HOST_CONFIG" | sed 's/.*= *"\([^"]*\)".*/\1/')"

export BOOTSTRAP_USER FLAKE HOST_CONFIG
