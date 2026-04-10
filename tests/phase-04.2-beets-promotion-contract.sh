#!/usr/bin/env bash
set -euo pipefail

BEETS_MODULE="modules/services/beets-inbox.nix"
BEETS_RUNTIME="modules/services/beets-inbox-runtime.nix"
BEETS_RUNNER="scripts/beets-inbox-runner.sh"
BEETS_CONFIG="scripts/beets-config.yaml"
SERVICE_FLOW_CONTRACT="tests/phase-04-service-flow-contract.sh"
NAVIDROME_FILE="modules/services/navidrome.nix"

rg --fixed-strings --quiet 'import ./beets-inbox-runtime.nix {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pkgs,' "$BEETS_MODULE"
rg --fixed-strings --quiet 'inputs,' "$BEETS_MODULE"
rg --fixed-strings --quiet '...' "$BEETS_MODULE"
rg --fixed-strings --quiet '}:' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pkgsUnstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };' "$BEETS_MODULE"
rg --fixed-strings --quiet 'inherit pkgsUnstable;' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pkgsUnstable.python3Packages.beets.override {' "$BEETS_RUNTIME"
rg --fixed-strings --quiet '{ pkgsUnstable }:' "$BEETS_RUNTIME"
rg --fixed-strings --quiet 'bandcamp = {' "$BEETS_RUNTIME"
rg --fixed-strings --quiet 'propagatedBuildInputs = [ pkgsUnstable.python3Packages.beetcamp ];' "$BEETS_RUNTIME"
rg --fixed-strings --quiet 'users.users.beets = {' "$BEETS_MODULE"
rg --fixed-strings --quiet 'extraGroups = [' "$BEETS_MODULE"
rg --fixed-strings --quiet '"music-ingest"' "$BEETS_MODULE"
rg --fixed-strings --quiet '"media"' "$BEETS_MODULE"
rg --fixed-strings --quiet '"remediation"' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-inbox-runner.sh' "$BEETS_MODULE"
rg --fixed-strings --quiet '../../scripts/beets-config.yaml' "$BEETS_MODULE"

if ! rg --fixed-strings --quiet 'TARGET_PATH="${1:-/srv/media/inbox}"' "$BEETS_RUNNER"; then
	echo 'missing all-inbox target default in runner: TARGET_PATH="${1:-/srv/media/inbox}"'
	exit 1
fi

rg --fixed-strings --quiet 'SETTLE_SECONDS="${BEETS_SETTLE_SECONDS:-10}"' "$BEETS_RUNNER"
rg --fixed-strings --quiet "find \"\$CANONICAL_TARGET\" -type f -name '*.tmp' -print -quit" "$BEETS_RUNNER"
rg --fixed-strings --quiet 'sleep "$SETTLE_SECONDS"' "$BEETS_RUNNER"

rg --fixed-strings --quiet 'UNTAGGED_ROOT="/srv/media/library/untagged"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'quiet_fallback: skip' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'plugins: bandcamp discogs importfeeds fetchart embedart fromfilename inline' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'fetchart:' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'embedart:' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'cautious: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'auto: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'cover_names: cover front folder art album' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'sources: filesystem coverart discogs itunes amazon albumart' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'ifempty: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'beets/discogs_token' hosts/oci-melb-1/default.nix
rg --fixed-strings --quiet 'sops.templates."beets-config.yaml"' hosts/oci-melb-1/default.nix
rg --fixed-strings --quiet 'config.sops.placeholder.beets_discogs_token' hosts/oci-melb-1/default.nix
rg --fixed-strings --quiet 'd /srv/data/beets/importfeeds 0750 beets beets - -' "$BEETS_MODULE"
rg --fixed-strings --quiet 'formats: [m3u]' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'dir: /srv/data/beets/importfeeds' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'm3u_name: imported.m3u' "$BEETS_CONFIG"
rg --fixed-strings --quiet '/srv/data/beets/logs' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'systemd.timers.beets-inbox-backstop' "$BEETS_MODULE"
rg --fixed-strings --quiet 'enable = false;' "$BEETS_MODULE"
rg --fixed-strings --quiet 'OnUnitActiveSec = "15m"' "$BEETS_MODULE"
rg --fixed-strings --quiet 'pathConfig.PathModified = "/srv/media/inbox";' "$BEETS_MODULE"
rg --fixed-strings --quiet 'd /srv/media/library 2775 root media - -' "$BEETS_MODULE"
rg --fixed-strings --quiet 'd /srv/media/library/tagged 2775 root media - -' "$BEETS_MODULE"
rg --fixed-strings --quiet 'd /srv/media/library/untagged 2775 root remediation - -' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/library/untagged - - - - group:media:r-x' "$BEETS_MODULE"
rg --fixed-strings --quiet 'a+ /srv/media/library/untagged - - - - default:group:media:r-x' "$BEETS_MODULE"
rg --fixed-strings --quiet 'demote_and_record_unresolved()' "$BEETS_RUNNER"
rg --fixed-strings --quiet "mapfile -d \$'\\0' -t LEFTOVER_AUDIO < <(find \"\$CANONICAL_TARGET\" -type f" "$BEETS_RUNNER"
rg --fixed-strings --quiet 'mv "$file" "$destination_file" || echo "beets-inbox-runner: failed to demote $file"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'mv "$file" "$destination_file"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'IMPORT_LOG_FILE="/srv/data/beets/logs/' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'RUNNER_LOG_FILE="/srv/data/beets/logs/' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'exec > >(tee -a "$RUNNER_LOG_FILE") 2>&1' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beets import failed; skipping demotion' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beets-inbox-runner: summary candidates=' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -C -l "$IMPORT_LOG_FILE"' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'beet -c /srv/data/beets/config.yaml import -q -C' "$BEETS_RUNNER"
rg --fixed-strings --quiet 'ExecStartPost = [ "+${beetsPermissionReconcile}/bin/beets-permission-reconcile" ];' "$BEETS_MODULE"
rg --fixed-strings --quiet 'singletons: no' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'group_albums: yes' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'missing_tracks: 0.0' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'unmatched_tracks: 0.0' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'paths:' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'default: $albumartist/$album%aunique{}/$source_stem' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'source_stem: |' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'source_stem, _ = os.path.splitext(source_name)' "$BEETS_CONFIG"
rg --fixed-strings --quiet 'return bytestring_path(source_stem)' "$BEETS_CONFIG"

rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library"' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'PlaylistsPath = "playlists";' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'AutoImportPlaylists = false;' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'ScanSchedule = "15m"' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'EnableTranscodingConfig = true;' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'DefaultDownsamplingFormat = "opus";' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'TranscodingCacheSize = "2GB";' "$SERVICE_FLOW_CONTRACT"
rg --fixed-strings --quiet 'FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";' "$SERVICE_FLOW_CONTRACT"

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

if rg --fixed-strings --quiet '/srv/media/untagged' "$BEETS_MODULE" ||
	rg --fixed-strings --quiet '/srv/media/untagged' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet '/srv/media/untagged' "$BEETS_CONFIG"; then
	echo 'untagged path must live under /srv/media/library/untagged'
	exit 1
fi

if rg --fixed-strings --quiet 'runner.lock' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet 'flock -n' "$BEETS_RUNNER"; then
	echo 'runner must rely on native systemd single-instance semantics, not custom lockfiles'
	exit 1
fi

if rg --fixed-strings --quiet 'import -q -C -l "$IMPORT_LOG_FILE" "$CANONICAL_TARGET" >/dev/null 2>&1 || true' "$BEETS_RUNNER" ||
	rg --fixed-strings --quiet 'import -q -p -C -l "$IMPORT_LOG_FILE" "$CANONICAL_TARGET" >/dev/null 2>&1 || true' "$BEETS_RUNNER"; then
	echo 'runner must not suppress/be ignore beets import failures'
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

if rg --fixed-strings --quiet 'MusicFolder = "/srv/media"' "$NAVIDROME_FILE"; then
	echo 'navidrome must read /srv/media/library'
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
