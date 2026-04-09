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
rg --fixed-strings --quiet 'users.groups.music-library = { };' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"music-ingest"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"music-library"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"d /srv/media/inbox 2775 root music-ingest - -"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"z /srv/media/inbox 2775 root music-ingest - -"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"a+ /srv/media/inbox - - - - group:music-ingest:rwx"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"a+ /srv/media/inbox - - - - group:music-library:r-x"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"a+ /srv/media/inbox - - - - default:group:music-ingest:rwx"' "$MUSIC_APP_FILE"
rg --fixed-strings --quiet '"a+ /srv/media/inbox - - - - default:group:music-library:r-x"' "$MUSIC_APP_FILE"

rg --fixed-strings --quiet 'MusicFolder = "/srv/media";' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'DataFolder = "/srv/data/navidrome";' "$NAVIDROME_FILE"
if rg --fixed-strings --quiet 'MusicFolder = "/srv/media/library";' "$NAVIDROME_FILE"; then
	echo 'navidrome music root must remain /srv/media, not /srv/media/library'
	exit 1
fi

# /srv/media/library is an allowed promoted subtree elsewhere in the stack.
rg --fixed-strings --quiet '/srv/media/library' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"z /srv/media/library 2775 syncthing music-library - -"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/library - - - - group:music-ingest:rwx"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/library - - - - group:music-library:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/library - - - - default:group:music-ingest:rwx"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/library - - - - default:group:music-library:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"z /srv/media/untagged 2755 syncthing music-library - -"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/untagged - - - - group:music-ingest:rwx"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/untagged - - - - group:music-library:r-x"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/untagged - - - - default:group:music-ingest:rwx"' modules/services/beets-inbox.nix
rg --fixed-strings --quiet '"a+ /srv/media/untagged - - - - default:group:music-library:r-x"' modules/services/beets-inbox.nix

rg --fixed-strings --quiet 'dataDir = "/srv/media";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'path = "/srv/media";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet 'type = "sendreceive";' "$SYNCTHING_FILE"
rg --fixed-strings --quiet '"d /srv/media 0755 root root - -"' "$MUSIC_APP_FILE"
if rg --fixed-strings --quiet '"a+ /srv/media - - - - ' "$MUSIC_APP_FILE" ||
	rg --fixed-strings --quiet '"a+ /srv/media - - - - ' modules/services/beets-inbox.nix; then
	echo 'root /srv/media must not carry blanket ACL entries'
	exit 1
fi
if rg --fixed-strings --quiet '/srv/data/inbox' "$SYNCTHING_FILE"; then
	echo 'syncthing must not claim generic /srv/data/inbox ownership'
	exit 1
fi

rg --fixed-strings --quiet '/srv/media/inbox/slskd' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media/slskd/incomplete' "$SLSKD_FILE"
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
