#!/usr/bin/env bash
set -euo pipefail

SYNCTHING_FILE="modules/services/syncthing.nix"

rg --fixed-strings --quiet 'enable = true;' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'openDefaultPorts = false;' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'settings.folders."media"' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'path = "/srv/data/media";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'type = "sendreceive";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'versioning = {' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'type = "trashcan";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'cleanoutDays = "30";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'cleanupIntervalS = "86400";' "$SYNCTHING_FILE"
