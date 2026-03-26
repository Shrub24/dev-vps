#!/usr/bin/env bash
set -euo pipefail

FILE="hosts/oci-melb-1/default.nix"

grep -q "../../modules/services/syncthing.nix" "$FILE"
grep -q "../../modules/services/navidrome.nix" "$FILE"
grep -q "../../modules/services/slskd.nix" "$FILE"
grep -q "../../modules/profiles/worker-interface.nix" "$FILE"

grep -q 'trustedInterfaces = \[ "tailscale0" \]' "$FILE"
grep -q 'navidrome = {' "$FILE"
grep -q 'slskd = {' "$FILE"
grep -q 'syncthing.service' "$FILE"
grep -q 'network-online.target' "$FILE"
