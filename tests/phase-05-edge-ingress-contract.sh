#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.do-admin-1.config'
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.applications.edge-ingress.enable" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.services.edge-proxy-ingress.role" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.services.caddy.enable" >/dev/null
echo "phase-05-edge-ingress-contract: PASS"
