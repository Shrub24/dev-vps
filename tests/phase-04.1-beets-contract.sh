#!/usr/bin/env bash
set -euo pipefail

MUSIC_APP_FILE="modules/applications/music.nix"
BEETS_MODULE="modules/services/beets-inbox.nix"
BEETS_RUNNER="scripts/beets-inbox-runner.sh"
BEETS_CONFIG="scripts/beets-config.yaml"

rg --fixed-strings --quiet '../../modules/services/beets-inbox.nix' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'import ./beets-inbox-runtime.nix {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'inherit pkgsUnstable;' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-inbox-runner.sh' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-config.yaml' "$BEETS_MODULE"
rg --fixed-strings --quiet 'users.users.beets = {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'extraGroups = [' "$BEETS_MODULE"
rg --fixed-strings --quiet '"music-ingest"' "$BEETS_MODULE"

rg --fixed-strings --quiet 'pathConfig.PathModified = "/srv/media/inbox";' "$BEETS_MODULE"
rg --fixed-strings --quiet 'BEETSDIR=/srv/data/beets' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'directory: /srv/media/library' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -C' "$BEETS_RUNNER"

rg --fixed-strings --quiet 'copy: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'move: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'link: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'hardlink: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'write: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'quiet: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'quiet_fallback: asis' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'singletons: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'group_albums: yes' "$BEETS_CONFIG"

rg --fixed-strings --quiet 'discogs' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'beatport' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'bandcamp' "$BEETS_CONFIG"

rg --fixed-strings --quiet '/srv/data/beets/logs' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'IMPORT_LOG_FILE="/srv/data/beets/logs/' "$BEETS_RUNNER"

if rg --fixed-strings --quiet 'soundcloud' "$BEETS_MODULE" ||
	rg --fixed-strings --quiet 'soundcloud' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet 'soundcloud' "$BEETS_CONFIG"; then
	echo 'soundcloud must stay deferred for phase 04.1'
	exit 1
fi

if rg --quiet '^\s*directory: /srv/media$' "$BEETS_CONFIG"; then
	echo 'beets import scope must stay inbox-only, not global /srv/media'
	exit 1
fi

if rg --fixed-strings --quiet '/srv/media/slskd' "$BEETS_MODULE" ||
	rg --fixed-strings --quiet '/srv/media/slskd' "$BEETS_RUNNER"; then
	echo 'beets watch scope must stay under /srv/media/inbox'
	exit 1
fi
