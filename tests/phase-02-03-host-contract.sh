#!/usr/bin/env bash
set -euo pipefail

FILE="hosts/oci-melb-1/default.nix"

rg --fixed-strings --quiet '../../modules/services/syncthing.nix' "$FILE"
rg --fixed-strings --quiet '../../modules/services/navidrome.nix' "$FILE"
rg --fixed-strings --quiet '../../modules/services/slskd.nix' "$FILE"
rg --fixed-strings --quiet '../../modules/profiles/worker-interface.nix' "$FILE"

rg --fixed-strings --quiet 'trustedInterfaces = [ "tailscale0" ]' "$FILE"
rg --fixed-strings --quiet 'systemd.services.navidrome = {' "$FILE"
rg --fixed-strings --quiet 'systemd.services.slskd = {' "$FILE"
rg --fixed-strings --quiet 'wants = [' "$FILE"
rg --fixed-strings --quiet 'after = [' "$FILE"
rg --fixed-strings --quiet '"network-online.target"' "$FILE"
rg --fixed-strings --quiet '"syncthing.service"' "$FILE"
