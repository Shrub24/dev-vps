#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.services.syncthing.enable" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.services.navidrome.enable" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.services.slskd.enable" >/dev/null
echo "phase-03-operations-contract: PASS"
