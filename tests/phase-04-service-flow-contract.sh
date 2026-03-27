#!/usr/bin/env bash
set -euo pipefail

NAVIDROME_FILE="modules/services/navidrome.nix"
SYNCTHING_FILE="modules/services/syncthing.nix"
SLSKD_FILE="modules/services/slskd.nix"

rg --fixed-strings --quiet 'MusicFolder = "/srv/data/media";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'DataFolder = "/srv/data/navidrome";' "$NAVIDROME_FILE"

rg --fixed-strings --quiet 'path = "/srv/data/media";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'type = "sendreceive";' "$SYNCTHING_FILE"

rg --fixed-strings --quiet '/srv/data/inbox/complete' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/data/inbox/incomplete' "$SLSKD_FILE"

if rg --fixed-strings --quiet '/srv/data/inbox' "$NAVIDROME_FILE"; then
  echo 'duplicate staging path introduced in navidrome flow'
  exit 1
fi
