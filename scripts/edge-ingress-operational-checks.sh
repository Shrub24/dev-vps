#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/edge-ingress-operational-checks.sh <domain> [admin_path]
# Example:
#   scripts/edge-ingress-operational-checks.sh termix.shrublab.xyz /

DOMAIN="${1:-}"
ADMIN_PATH="${2:-/}"

if [[ -z "$DOMAIN" ]]; then
	echo "usage: $0 <domain> [admin_path]"
	exit 2
fi

echo "== caddy service =="
systemctl is-active caddy

echo "== caddy config validate =="
caddy validate --config /etc/caddy/Caddyfile

echo "== certificate presence =="
test -s "/var/lib/acme/${DOMAIN#*.}/fullchain.pem"
test -s "/var/lib/acme/${DOMAIN#*.}/key.pem"

echo "== route reachability (HEAD) =="
curl -fsSI "https://${DOMAIN}/" >/dev/null

echo "== admin route policy (expect 403 without Access header) =="
status="$(curl -sk -o /dev/null -w '%{http_code}' "https://${DOMAIN}${ADMIN_PATH}")"
if [[ "$status" != "403" ]]; then
	echo "expected 403 for unauthenticated admin path, got ${status}"
	exit 1
fi

echo "edge ingress checks passed"
