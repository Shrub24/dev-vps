#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-do-admin-1}"

mkdir -p generated/policy
nix eval --json --no-write-lock-file --apply "f: f { hostName = \"${HOST}\"; }" --file lib/policy-export.nix > generated/policy/web-services.json
echo "Exported generated/policy/web-services.json for ${HOST}"
