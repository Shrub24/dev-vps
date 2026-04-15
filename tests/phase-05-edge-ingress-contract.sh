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
rg --fixed-strings --quiet 'webServicesPolicy = import ../../policy/web-services.nix;' "$EDGE_HOST"
rg --fixed-strings --quiet 'policyLib = import ../../lib/policy.nix { inherit lib; };' "$EDGE_HOST"
rg --fixed-strings --quiet 'routes = edgeRoutes;' "$EDGE_HOST"

nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.navidrome.subdomain == "music"' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.navidrome.cloudflareAccessRequired == false' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.navidrome.exposureMode == "tailscale-upstream"' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.vaultwarden-admin.cloudflareAccessRequired == false' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.termix-admin.cloudflareAccessRequired == true' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.termix-admin.subdomain == "termix"' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.syncthing-admin.exposureMode == "tailscale-upstream"' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.admin-homepage.subdomain == "admin"' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'

nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.navidrome.authenticatedOriginPullsRequired == false' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'cfg: cfg.services."edge-proxy-ingress".routes.termix-admin.authenticatedOriginPullsRequired == true' path:.#nixosConfigurations.do-admin-1.config | rg --fixed-strings --quiet 'true'

rg --fixed-strings --quiet 'role = "origin";' "$ORIGIN_HOST"
