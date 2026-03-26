#!/usr/bin/env bash
set -euo pipefail

TAILSCALE_FILE="modules/services/tailscale.nix"
HOST_FILE="hosts/oci-melb-1/default.nix"
NAVIDROME_FILE="modules/services/navidrome.nix"
SLSKD_FILE="modules/services/slskd.nix"

rg --fixed-strings --quiet 'services.tailscale = {' "$TAILSCALE_FILE"
rg --fixed-strings --quiet 'enable = true;' "$TAILSCALE_FILE"
rg --fixed-strings --quiet 'openFirewall = false;' "$TAILSCALE_FILE"

rg --fixed-strings --quiet 'trustedInterfaces = [ "tailscale0" ]' "$HOST_FILE"

rg --fixed-strings --quiet 'openFirewall = false;' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'openFirewall = false;' "$SLSKD_FILE"
