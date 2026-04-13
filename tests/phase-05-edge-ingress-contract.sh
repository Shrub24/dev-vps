#!/usr/bin/env bash
set -euo pipefail

EDGE_SERVICE="modules/services/edge-proxy-ingress.nix"
EDGE_APP="modules/applications/edge-ingress.nix"
EDGE_HOST="hosts/do-admin-1/default.nix"
ORIGIN_HOST="hosts/oci-melb-1/default.nix"

rg --fixed-strings --quiet 'services."edge-proxy-ingress"' "$EDGE_SERVICE"
rg --fixed-strings --quiet 'type = lib.types.enum [' "$EDGE_SERVICE"
rg --fixed-strings --quiet '"direct"' "$EDGE_SERVICE"
rg --fixed-strings --quiet '"tailscale-upstream"' "$EDGE_SERVICE"
rg --fixed-strings --quiet '"tailscale-only"' "$EDGE_SERVICE"
rg --fixed-strings --quiet 'route.exposureMode == "tailscale-only" || route.declarePublic' "$EDGE_SERVICE"
rg --fixed-strings --quiet 'not header Cf-Access-Authenticated-User-Email *' "$EDGE_SERVICE"
rg --fixed-strings --quiet 'encode zstd' "$EDGE_SERVICE"
rg --fixed-strings --quiet 'dnsProvider = "cloudflare";' "$EDGE_SERVICE"

if rg --fixed-strings --quiet 'trusted_proxies_strict' "$EDGE_SERVICE"; then
	echo 'invalid trusted_proxies_strict directive reintroduced'
	exit 1
fi

if rg --fixed-strings --quiet 'withPlugins' "$EDGE_SERVICE"; then
	echo 'caddy withPlugins should not be required for ACME DNS-01 mode'
	exit 1
fi

rg --fixed-strings --quiet 'applications."edge-ingress"' "$EDGE_APP"
rg --fixed-strings --quiet 'services."edge-proxy-ingress"' "$EDGE_APP"

rg --fixed-strings --quiet 'role = "edge";' "$EDGE_HOST"
rg --fixed-strings --quiet 'exposureMode = "direct";' "$EDGE_HOST"
rg --fixed-strings --quiet 'exposureMode = "tailscale-upstream";' "$EDGE_HOST"
rg --fixed-strings --quiet 'exposureMode = "tailscale-only";' "$EDGE_HOST"
rg --fixed-strings --quiet 'cloudflareAccessRequired = true;' "$EDGE_HOST"

rg --fixed-strings --quiet 'role = "origin";' "$ORIGIN_HOST"
