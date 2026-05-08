#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

SED_ANCHORS="${TMP}/anchors.txt"
grep -oP '&\w+\s+\S+' "$REPO_ROOT/.sops.yaml" | while read -r line; do
  anchor=$(echo "$line" | awk '{print $1}' | sed 's/^&//')
  age_key=$(echo "$line" | awk '{print $2}')
  echo "$anchor $age_key"
done > "$SED_ANCHORS"

declare -A ANCHOR_TO_HOST
while read -r anchor age_key; do
  case "$anchor" in
    oci_melb_1_age) ANCHOR_TO_HOST[$anchor]="oci-melb-1" ;;
    do_admin_1_age) ANCHOR_TO_HOST[$anchor]="do-admin-1" ;;
  esac
done < "$SED_ANCHORS"

echo "=== Secret scope validation ==="
echo ""

PASS=0
FAIL=0

while IFS=$'\t' read -r scope expected; do
  echo "[scope] secrets/$scope"
  echo "  expected readers: $expected"

  rule_block=$(grep -A 10 "secrets/$scope" "$REPO_ROOT/.sops.yaml" | grep "\*" || true)
  if [ -z "$rule_block" ]; then
    echo "  ❌  MISSING: no rule found for secrets/$scope"
    FAIL=$((FAIL+1))
    echo ""
    continue
  fi

  IFS=',' read -ra HOSTS <<< "$expected"
  for host in "${HOSTS[@]}"; do
    anchor=""
    case "$host" in
      "oci-melb-1") anchor="oci_melb_1_age" ;;
      "do-admin-1") anchor="do_admin_1_age" ;;
    esac
    if grep -A 10 "secrets/$scope" "$REPO_ROOT/.sops.yaml" | grep -q "\*${anchor}"; then
      echo "  ✅ $host"
    else
      echo "  ❌  $host: anchor *${anchor} not found in rule for secrets/$scope"
      FAIL=$((FAIL+1))
    fi
  done

  grep -A 10 "secrets/$scope" "$REPO_ROOT/.sops.yaml" | grep -oP '\*\w+_age' | while read -r found_anchor; do
    found_host="${ANCHOR_TO_HOST[$found_anchor]:-}"
    if [ -n "$found_host" ]; then
      if ! echo "$expected" | grep -q "$found_host"; then
        echo "  ⚠️   WARNING: $found_host ($found_anchor) can decrypt secrets/$scope but may not need it"
      fi
    fi
  done

  PASS=$((PASS+1))
  echo ""
done < <(
  nix eval --json --file "$REPO_ROOT/tests/fixtures/secret-scope.nix" \
    | python3 -c 'import json, sys; data = json.load(sys.stdin); [print(f"{scope}\t{",".join(readers)}") for scope, readers in data.items()]'
)

echo "=== Result: $PASS scopes checked ==="
if [ "$FAIL" -gt 0 ]; then
  echo "❌  $FAIL FAILURES — update .sops.yaml to match topology"
  exit 1
else
  echo "✅ All checks passed"
fi
