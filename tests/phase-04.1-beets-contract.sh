#!/usr/bin/env bash
set -euo pipefail

MUSIC_APP_FILE="modules/applications/music.nix"
BEETS_MODULE="modules/services/beets-inbox.nix"
BEETS_RUNNER="scripts/beets-inbox-runner.sh"
BEETS_CONFIG="scripts/beets-config.yaml"

rg --fixed-strings --quiet '../../modules/services/beets-inbox.nix' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'pkgsUnstable.python3Packages.beets.override {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pluginOverrides = {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'propagatedBuildInputs = [ pkgsUnstable.python3Packages.beetcamp ];' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-inbox-runner.sh' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-config.yaml' "$BEETS_MODULE"
rg --fixed-strings --quiet 'users.users.beets = {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'extraGroups = [' "$BEETS_MODULE"
rg --fixed-strings --quiet '"music-ingest"' "$BEETS_MODULE"
rg --fixed-strings --quiet '"media"' "$BEETS_MODULE"

rg --fixed-strings --quiet 'pathConfig.PathModified = "/srv/media/inbox";' "$BEETS_MODULE"
rg --fixed-strings --quiet 'BEETSDIR=/srv/data/beets' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'directory: /srv/media/library' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'source_stem: |' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'source_stem, _ = os.path.splitext(source_name)' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'default: $albumartist/$album%aunique{}/$source_stem' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -C' "$BEETS_RUNNER"

rg --fixed-strings --quiet 'copy: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'move: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'link: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'hardlink: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'write: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'quiet_fallback: skip' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'singletons: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'group_albums: yes' "$BEETS_CONFIG"

rg --fixed-strings --quiet 'plugins: bandcamp discogs fetchart embedart fromfilename inline' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'fetchart:' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'embedart:' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'cautious: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'auto: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'cover_names: cover front folder art album' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'sources: filesystem cover_art_url coverart discogs itunes albumart' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'ifempty: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'beets/discogs_token' hosts/oci-melb-1/default.nix
rg --fixed-strings --quiet 'sops.templates."beets-config.yaml"' hosts/oci-melb-1/default.nix

rg --fixed-strings --quiet '/srv/data/beets/logs' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'IMPORT_LOG_FILE="/srv/data/beets/logs/' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'RUNNER_LOG_FILE="/srv/data/beets/logs/' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'exec > >(tee -a "$RUNNER_LOG_FILE") 2>&1' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beets-permission-reconcile' "$BEETS_MODULE"

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

if rg --quiet '^\s*quiet:\s*yes\s*$' "$BEETS_CONFIG"; then
	echo 'beets config must stay interactive-friendly; quiet mode belongs in runner CLI flags only'
	exit 1
fi

if rg --fixed-strings --quiet '/srv/media/slskd' "$BEETS_MODULE" ||
	rg --fixed-strings --quiet '/srv/media/slskd' "$BEETS_RUNNER"; then
	echo 'beets watch scope must stay under /srv/media/inbox'
	exit 1
fi
