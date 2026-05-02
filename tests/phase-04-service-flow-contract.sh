#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.applications.music.enable" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.services.navidrome.settings.MusicFolder" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.services.slskd.settings.directories.downloads" >/dev/null
echo "phase-04-service-flow-contract: PASS"
