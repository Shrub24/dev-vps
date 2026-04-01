#!/usr/bin/env bash
set -euo pipefail

BEETS_FILE="modules/services/beets-inbox.nix"
SERVICE_FLOW_CONTRACT="tests/phase-04-service-flow-contract.sh"
NAVIDROME_FILE="modules/services/navidrome.nix"

# Accept raw shell form and Nix-escaped shell form.
if ! rg --fixed-strings --quiet 'TARGET_PATH="${1:-/srv/media/inbox}"' "$BEETS_FILE" \
  && ! rg --fixed-strings --quiet "TARGET_PATH=\"''\${1:-/srv/media/inbox}\"" "$BEETS_FILE"; then
  echo 'missing all-inbox target default: TARGET_PATH="${1:-/srv/media/inbox}"'
  exit 1
fi

rg --fixed-strings --quiet 'LIBRARY_ROOT="/srv/media/library"' "$BEETS_FILE"
rg --fixed-strings --quiet 'quiet_fallback: asis' "$BEETS_FILE"
rg --fixed-strings --quiet 'plugins: discogs beatport bandcamp fromfilename' "$BEETS_FILE"
rg --fixed-strings --quiet '/srv/data/beets/reports' "$BEETS_FILE"
rg --fixed-strings --quiet '/srv/data/beets/unresolved' "$BEETS_FILE"
rg --fixed-strings --quiet 'systemd.timers.beets-inbox-backstop' "$BEETS_FILE"
rg --fixed-strings --quiet 'OnUnitActiveSec = "15m"' "$BEETS_FILE"
rg --fixed-strings --quiet 'basename "$file"' "$BEETS_FILE"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -s -C' "$BEETS_FILE"

rg --fixed-strings --quiet 'MusicFolder = "/srv/media"' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library"' "$SERVICE_FLOW_CONTRACT"

if rg --fixed-strings --quiet 'PathExistsGlob = "/srv/media/inbox/slskd/*"' "$BEETS_FILE"; then
  echo 'beets scope must be all-inbox, not slskd-only'
  exit 1
fi

if rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library"' "$NAVIDROME_FILE"; then
  echo 'navidrome must continue reading /srv/media, not /srv/media/library'
  exit 1
fi

for disallowed in \
  'move: yes' \
  'copy: yes' \
  'link: yes' \
  'hardlink: yes' \
  'soundcloud' \
  '/srv/media/library/slskd'
do
  if rg --fixed-strings --quiet "$disallowed" "$BEETS_FILE"; then
    echo "found disallowed pattern in beets worker: $disallowed"
    exit 1
  fi
done
