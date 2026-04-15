#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-do-admin-1}"
OUT="generated/policy/web-services.json"
TMP="$(mktemp)"

cleanup() {
  rm -f "$TMP"
}
trap cleanup EXIT

nix eval --json --no-write-lock-file --apply "f: f { hostName = \"${HOST}\"; }" --file lib/policy-export.nix > "$TMP"

if [[ ! -f "$OUT" ]]; then
  echo "$OUT is missing (run: ./lib/export-web-services-policy.sh ${HOST})"
  exit 1
fi

if ! cmp -s "$TMP" "$OUT"; then
  echo "$OUT is out of date (run: ./lib/export-web-services-policy.sh ${HOST})"
  exit 1
fi

echo "web-services policy export is up to date for ${HOST}"
