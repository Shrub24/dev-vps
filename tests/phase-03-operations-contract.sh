#!/usr/bin/env bash
set -euo pipefail

JUSTFILE="justfile"
SYNCTHING_FILE="modules/services/syncthing.nix"
NAVIDROME_FILE="modules/services/navidrome.nix"
SLSKD_FILE="modules/services/slskd.nix"

rg --fixed-strings --quiet 'redeploy:' "$JUSTFILE"
rg --fixed-strings --quiet 'nix run nixpkgs#nixos-rebuild -- switch' "$JUSTFILE"
rg --fixed-strings --quiet -- '--flake path:.#oci-melb-1' "$JUSTFILE"
rg --fixed-strings --quiet -- '--target-host {{target_user}}@{{target_host}}' "$JUSTFILE"
rg --fixed-strings --quiet -- '--build-host {{target_user}}@{{target_host}}' "$JUSTFILE"

rg --fixed-strings --quiet '/srv/data/syncthing/config' "$SYNCTHING_FILE"
rg --fixed-strings --quiet '/srv/media' "$SYNCTHING_FILE"
rg --fixed-strings --quiet '/srv/data/navidrome' "$NAVIDROME_FILE"
rg --fixed-strings --quiet '/srv/media' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media/inbox/slskd' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media/slskd/incomplete' "$SLSKD_FILE"
