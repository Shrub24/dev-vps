#!/usr/bin/env bash
set -euo pipefail

BEETS_MODULE="modules/services/beets-inbox.nix"
BEETS_RUNTIME="modules/services/beets-inbox-runtime.nix"
BEETS_RUNNER="scripts/beets-inbox-runner.sh"
BEETS_CONFIG="scripts/beets-config.yaml"
SERVICE_FLOW_CONTRACT="tests/phase-04-service-flow-contract.sh"
NAVIDROME_FILE="modules/services/navidrome.nix"

rg --fixed-strings --quiet 'import ./beets-inbox-runtime.nix {' "$BEETS_MODULE"
rg --fixed-strings --quiet '{ pkgs, inputs, ... }:' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pkgsUnstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };' "$BEETS_MODULE"
rg --fixed-strings --quiet 'inherit pkgsUnstable;' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pkgsUnstable.python3Packages.beets.override {' "$BEETS_RUNTIME"
rg --fixed-strings --quiet '{ pkgsUnstable }:' "$BEETS_RUNTIME"
rg --fixed-strings --quiet 'bandcamp = {' "$BEETS_RUNTIME"
rg --fixed-strings --quiet 'propagatedBuildInputs = [ pkgsUnstable.python3Packages.beetcamp ];' "$BEETS_RUNTIME"
rg --fixed-strings --quiet 'users.users.beets = {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'extraGroups = [' "$BEETS_MODULE"
rg --fixed-strings --quiet '"music-ingest"' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-inbox-runner.sh' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-config.yaml' "$BEETS_MODULE"

if ! rg --fixed-strings --quiet 'TARGET_PATH="${1:-/srv/media/inbox}"' "$BEETS_RUNNER"; then
	echo 'missing all-inbox target default in runner: TARGET_PATH="${1:-/srv/media/inbox}"'
	exit 1
fi

rg --fixed-strings --quiet 'SETTLE_SECONDS="${BEETS_SETTLE_SECONDS:-10}"' "$BEETS_RUNNER"
rg --fixed-strings --quiet "find \"\$CANONICAL_TARGET\" -type f -name '*.tmp' -print -quit" "$BEETS_RUNNER"
rg --fixed-strings --quiet 'sleep "$SETTLE_SECONDS"' "$BEETS_RUNNER"

rg --fixed-strings --quiet 'UNTAGGED_ROOT="/srv/media/untagged"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'quiet_fallback: asis' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'plugins: discogs beatport bandcamp fromfilename inline' "$BEETS_CONFIG"
rg --fixed-strings --quiet '/srv/data/beets/logs' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'systemd.timers.beets-inbox-backstop' "$BEETS_MODULE"
rg --fixed-strings --quiet 'OnUnitActiveSec = "15m"' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pathConfig.PathModified = "/srv/media/inbox";' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/inbox - - - - group:music-ingest:rwx' "modules/applications/music.nix"
rg --fixed-strings --quiet 'a+ /srv/media/inbox - - - - group:music-library:r-x' "modules/applications/music.nix"
rg --fixed-strings --quiet 'a+ /srv/media/inbox - - - - default:group:music-ingest:rwx' "modules/applications/music.nix"
rg --fixed-strings --quiet 'a+ /srv/media/inbox - - - - default:group:music-library:r-x' "modules/applications/music.nix"
rg --fixed-strings --quiet 'a+ /srv/media/library - - - - group:music-ingest:rwx' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/library - - - - group:music-library:r-x' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/library - - - - default:group:music-ingest:rwx' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/library - - - - default:group:music-library:r-x' "$BEETS_MODULE"
rg --fixed-strings --quiet 'd /srv/media/untagged 2755 syncthing music-library - -' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/untagged - - - - group:music-ingest:rwx' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/untagged - - - - group:music-library:r-x' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/untagged - - - - default:group:music-ingest:rwx' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/untagged - - - - default:group:music-library:r-x' "$BEETS_MODULE"
rg --fixed-strings --quiet 'demote_and_record_unresolved()' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'collect_audio_files "$CANONICAL_TARGET" LEFTOVER_AUDIO' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'mv "$file" "$destination_file" || echo "beets-inbox-runner: failed to demote $file"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'mv "$file" "$destination_file"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'IMPORT_LOG_FILE="/srv/data/beets/logs/' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -C -l "$IMPORT_LOG_FILE"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -C' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'singletons: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'group_albums: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'missing_tracks: 0.1' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'unmatched_tracks: 0.1' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'paths:' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'default: $albumartist/$album%aunique{}/$filename' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'return bytestring_path(os.path.basename(path))' "$BEETS_CONFIG"

rg --fixed-strings --quiet 'MusicFolder = "/srv/media"' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library"' "$SERVICE_FLOW_CONTRACT"

if rg --fixed-strings --quiet 'PathExistsGlob = "/srv/media/inbox/slskd/*"' "$BEETS_MODULE"; then
	echo 'beets scope must be all-inbox, not slskd-only'
	exit 1
fi

if rg --fixed-strings --quiet 'PathExistsGlob = "/srv/media/inbox/*"' "$BEETS_MODULE"; then
	echo 'beets trigger must be PathModified on /srv/media/inbox'
	exit 1
fi

if rg --fixed-strings --quiet 'a+ /srv/media - - - - ' "$BEETS_MODULE" ||
	rg --fixed-strings --quiet 'a+ /srv/media - - - - ' "modules/applications/music.nix"; then
	echo 'root /srv/media must not carry blanket ACL entries'
	exit 1
fi

if rg --fixed-strings --quiet 'runner.lock' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet 'flock -n' "$BEETS_RUNNER"; then
	echo 'runner must rely on native systemd single-instance semantics, not custom lockfiles'
	exit 1
fi

if rg --fixed-strings --quiet 'pythonCatchConflicts = false;' "$BEETS_RUNTIME"; then
	echo 'runtime must not rely on temporary pythonCatchConflicts workaround'
	exit 1
fi

if rg --fixed-strings --quiet 'MediaFile' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet 'python - "$file"' "$BEETS_RUNNER"; then
	echo 'runner must not perform custom metadata extraction/path building logic'
	exit 1
fi

if rg --fixed-strings --quiet '/srv/data/beets/reports' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet '/srv/data/beets/unresolved' "$BEETS_RUNNER"; then
	echo 'runner should rely on beets built-in import log instead of custom reports'
	exit 1
fi

if rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library"' "$NAVIDROME_FILE"; then
	echo 'navidrome must continue reading /srv/media, not /srv/media/library'
	exit 1
fi

for disallowed in \
	'copy: yes' \
	'link: yes' \
	'hardlink: yes' \
	'soundcloud' \
	'/srv/media/library/slskd'; do
	if rg --fixed-strings --quiet "$disallowed" "$BEETS_MODULE" ||
		rg --fixed-strings --quiet "$disallowed" "$BEETS_RUNNER" ||
		rg --fixed-strings --quiet "$disallowed" "$BEETS_CONFIG"; then
		echo "found disallowed pattern in beets worker: $disallowed"
		exit 1
	fi
done
