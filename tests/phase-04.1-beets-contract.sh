#!/usr/bin/env bash
set -euo pipefail

MUSIC_APP_FILE="modules/applications/music.nix"
BEETS_FILE="modules/services/beets-inbox.nix"

rg --fixed-strings --quiet '../../modules/services/beets-inbox.nix' "$MUSIC_APP_FILE"

rg --fixed-strings --quiet 'PathExistsGlob = "/srv/media/inbox/slskd/*"' "$BEETS_FILE"
rg --fixed-strings --quiet 'BEETSDIR=/srv/data/beets' "$BEETS_FILE"
rg --fixed-strings --quiet 'directory: /srv/media/inbox' "$BEETS_FILE"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -s -C' "$BEETS_FILE"

rg --fixed-strings --quiet 'copy: no' "$BEETS_FILE"
rg --fixed-strings --quiet 'move: no' "$BEETS_FILE"
rg --fixed-strings --quiet 'link: no' "$BEETS_FILE"
rg --fixed-strings --quiet 'hardlink: no' "$BEETS_FILE"
rg --fixed-strings --quiet 'write: yes' "$BEETS_FILE"
rg --fixed-strings --quiet 'quiet: yes' "$BEETS_FILE"
rg --fixed-strings --quiet 'quiet_fallback: skip' "$BEETS_FILE"

rg --fixed-strings --quiet 'discogs' "$BEETS_FILE"
rg --fixed-strings --quiet 'beatport' "$BEETS_FILE"
rg --fixed-strings --quiet 'bandcamp' "$BEETS_FILE"

rg --fixed-strings --quiet '/srv/data/beets/reports' "$BEETS_FILE"
rg --fixed-strings --quiet '/srv/data/beets/unresolved' "$BEETS_FILE"

if rg --fixed-strings --quiet 'soundcloud' "$BEETS_FILE"; then
  echo 'soundcloud must stay deferred for phase 04.1'
  exit 1
fi

if rg --fixed-strings --quiet 'directory: /srv/media' "$BEETS_FILE"; then
  echo 'beets import scope must stay inbox-only, not global /srv/media'
  exit 1
fi

if rg --fixed-strings --quiet '/srv/media/slskd' "$BEETS_FILE"; then
  echo 'beets watch scope must stay under /srv/media/inbox/slskd'
  exit 1
fi
