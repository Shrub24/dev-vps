#!/usr/bin/env bash
set -euo pipefail

# Validate that .sops.yaml path rules match the canonical
# secret-to-host mapping defined in lib/secret-scope.nix.
#
# Usage: ./lib/check-secret-scope.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Parse .sops.yaml for age key anchors vs host name
# We read the anchor-name mapping from .sops.yaml anchors
SED_ANCHORS="${TMP}/anchors.txt"
grep -oP '&\w+\s+\S+' "$REPO_ROOT/.sops.yaml" | while read -r line; do
  anchor=$(echo "$line" | awk '{print $1}' | sed 's/^&//')
  age_key=$(echo "$line" | awk '{print $2}')
  echo "$anchor $age_key"
done > "$SED_ANCHORS"

# Map anchor name → host label
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

for path_key in \
  "applications/music:oci-melb-1" \
  "applications/admin:do-admin-1" \
  "applications/edge-ingress:oci-melb-1,do-admin-1" \
  "services/karakeep-pod:oci-melb-1" \
  "services/bifrost-gateway:oci-melb-1" \
  "hosts/oci-melb-1/system:oci-melb-1" \
  "hosts/do-admin-1/system:do-admin-1" \
  "hosts/oci-melb-1/oidc:oci-melb-1,do-admin-1" \
  "hosts/do-admin-1/oidc:do-admin-1,oci-melb-1"
do
  scope="${path_key%%:*}"
  expected="${path_key##*:}"
  echo "[scope] secrets/$scope"
  echo "  expected readers: $expected"

  # Find .sops.yaml rule for this scope
  rule_block=$(grep -A 10 "secrets/$scope" "$REPO_ROOT/.sops.yaml" | grep "\*" || true)
  if [ -z "$rule_block" ]; then
    echo "  ❌  MISSING: no rule found for secrets/$scope"
    FAIL=$((FAIL+1))
    echo ""
    continue
  fi

  # Check each expected host's age anchor appears in the rule
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

  # Check: no unexpected host anchors
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
done

echo "=== Result: $PASS scopes checked ==="
if [ "$FAIL" -gt 0 ]; then
  echo "❌  $FAIL FAILURES — update .sops.yaml to match topology"
  exit 1
else
  echo "✅ All checks passed"
fi
