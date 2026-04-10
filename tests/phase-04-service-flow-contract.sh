#!/usr/bin/env bash
set -euo pipefail

NAVIDROME_FILE="modules/services/navidrome.nix"
SYNCTHING_FILE="modules/services/syncthing.nix"
SLSKD_FILE="modules/services/slskd.nix"
MUSIC_APP_FILE="modules/applications/music.nix"
HOST_FILE="hosts/oci-melb-1/default.nix"

rg --fixed-strings --quiet '../../modules/applications/music.nix' "$HOST_FILE"
rg --fixed-strings --quiet '../../modules/services/syncthing.nix' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '../../modules/services/navidrome.nix' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '../../modules/services/slskd.nix' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'domain = "oci-melb-1";' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'environmentFile = "/var/lib/slskd/environment";' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'users.groups.music-ingest = { };' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'users.groups.media = { };' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet 'users.groups.remediation = { };' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"beets"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"music-ingest"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"media"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"remediation"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"d /srv/media/inbox 2775 root music-ingest - -"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"d /srv/media/library 2775 root media - -"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"d /srv/media/library/tagged 2775 root media - -"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"d /srv/media/library/untagged 2775 root remediation - -"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"a+ /srv/media/library/untagged - - - - group:media:r-x"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"a+ /srv/media/library/untagged - - - - default:group:media:r-x"' "$MUSIC_APP_FILE"

rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'DataFolder = "/srv/data/navidrome";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'PlaylistsPath = "playlists";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'AutoImportPlaylists = false;' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'ScanSchedule = "15m";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'EnableTranscodingConfig = true;' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'DefaultDownsamplingFormat = "opus";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'TranscodingCacheSize = "2GB";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'd /srv/media/library/playlists 0775 root media - -' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'needs-attention-untagged.nsp' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'C /srv/media/library/playlists/needs-attention-untagged.nsp 0644 root media' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'systemd.tmpfiles.settings.navidromeDirs = lib.mkForce {' "$NAVIDROME_FILE"
rg --fixed-strings --quiet '"${cfg.settings.DataFolder or "/var/lib/navidrome"}"."d"' "$NAVIDROME_FILE"
rg --fixed-strings --quiet '"${cfg.settings.CacheFolder or "/var/lib/navidrome/cache"}"."d"' "$NAVIDROME_FILE"
if rg --fixed-strings --quiet '"d /srv/media/library 0' "$NAVIDROME_FILE" ||
	rg --fixed-strings --quiet '"d /srv/media/library 7' "$NAVIDROME_FILE"; then
	echo 'navidrome must not own/manage the MusicFolder root via tmpfiles rules'
	exit 1
fi
if rg --fixed-strings --quiet '"${cfg.settings.MusicFolder or (WorkingDirectory + "/music")}"."d"' "$NAVIDROME_FILE"; then
	echo 'navidrome tmpfiles override must not recreate MusicFolder ownership rules'
	exit 1
fi
if rg --fixed-strings --quiet 'MusicFolder = "/srv/media";' "$NAVIDROME_FILE"; then
	echo 'navidrome music root must be /srv/media/library'
	exit 1
fi

# /srv/media/library is an allowed promoted subtree elsewhere in the stack.
rg --fixed-strings --quiet '/srv/media/library' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"d /srv/media/library 2775 root media - -"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"d /srv/media/library/tagged 2775 root media - -"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"d /srv/media/library/untagged 2775 root remediation - -"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/library/untagged - - - - group:media:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/library/untagged - - - - default:group:media:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/data/beets/logs - - - - user:dev:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/data/beets/logs - - - - default:user:dev:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet 'ExecStartPost = [ "+${beetsPermissionReconcile}/bin/beets-permission-reconcile" ];' modules/services/beets-inbox.nix

rg --fixed-strings --quiet 'dataDir = "/srv/data/syncthing";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'path = "/srv/media/library";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'type = "sendreceive";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet '"d /srv/media 0755 root root - -"' "$MUSIC_APP_FILE"
if rg --fixed-strings --quiet 'a+ /srv/media/inbox' "$MUSIC_APP_FILE" ||
	rg --fixed-strings --quiet 'a+ /srv/media/inbox' modules/services/beets-inbox.nix ||
	rg --fixed-strings --quiet 'a+ /srv/media/library/tagged' "$MUSIC_APP_FILE" ||
	rg --fixed-strings --quiet 'a+ /srv/media/library/tagged' modules/services/beets-inbox.nix; then
	echo 'media path ACL rules should be limited to /srv/media/library/untagged'
	exit 1
fi

if rg --fixed-strings --quiet '"a+ /srv/media - - - - ' "$MUSIC_APP_FILE" ||
	rg --fixed-strings --quiet '"a+ /srv/media - - - - ' modules/services/beets-inbox.nix; then
	echo 'root /srv/media must not carry blanket ACL entries'
	exit 1
fi

if rg --fixed-strings --quiet '/srv/media/untagged' modules/services/beets-inbox.nix; then
	echo 'untagged path must be nested under /srv/media/library'
	exit 1
fi
if rg --fixed-strings --quiet '/srv/data/inbox' "$SYNCTHING_FILE"; then
	echo 'syncthing must not claim generic /srv/data/inbox ownership'
	exit 1
fi

rg --fixed-strings --quiet '/srv/media/inbox/slskd' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media/slskd/incomplete' "$SLSKD_FILE"
rg --fixed-strings --quiet '"d /srv/media/inbox/slskd 0775 slskd music-ingest - -"' "$SLSKD_FILE"
rg --fixed-strings --quiet '"d /srv/media/slskd/incomplete 0775 slskd music-ingest - -"' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media' "$SLSKD_FILE"
if rg --fixed-strings --quiet '/srv/data/inbox/slskd' "$SLSKD_FILE"; then
	echo 'slskd downloads path still points at /srv/data'
	exit 1
fi
if rg --fixed-strings --quiet '/srv/data/slskd/incomplete' "$SLSKD_FILE"; then
	echo 'slskd incomplete path still points at /srv/data'
	exit 1
fi

if rg --fixed-strings --quiet '/srv/data/inbox' "$NAVIDROME_FILE"; then
	echo 'duplicate staging path introduced in navidrome flow'
	exit 1
fi
