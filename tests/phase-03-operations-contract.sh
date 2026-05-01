#!/usr/bin/env bash
set -euo pipefail

JUSTFILE="justfile"
SYNCTHING_FILE="modules/services/syncthing.nix"
NAVIDROME_FILE="modules/services/navidrome.nix"
SLSKD_FILE="modules/services/slskd.nix"

rg --fixed-strings --quiet 'deploy host:' "$JUSTFILE"
rg --fixed-strings --quiet 'deploy host rollback="true":' "$JUSTFILE"
rg --fixed-strings --quiet 'deploy-activate host:' "$JUSTFILE"
rg --fixed-strings --quiet 'deploy-no-rollback host:' "$JUSTFILE"
rg --fixed-strings --quiet 'redeploy-no-rollback host:' "$JUSTFILE"
rg --fixed-strings --quiet 'deploy-check:' "$JUSTFILE"
rg --fixed-strings --quiet 'ARGS=(--skip-checks)' "$JUSTFILE"
rg --fixed-strings --quiet 'if [[ "$ROLLBACK" == "false" ]]; then ARGS+=(--auto-rollback false); fi' "$JUSTFILE"
rg --fixed-strings --quiet 'nix run .#deploy-rs -- "${ARGS[@]}" ".#$HOST"' "$JUSTFILE"
rg --fixed-strings --quiet 'nix run .#deploy-rs -- --skip-checks --dry-activate ".#$HOST"' "$JUSTFILE"
rg --fixed-strings --quiet 'redeploy host rollback="true":' "$JUSTFILE"
rg --fixed-strings --quiet 'just deploy "$HOST" "$ROLLBACK"' "$JUSTFILE"
rg --fixed-strings --quiet 'just deploy "$HOST" "false"' "$JUSTFILE"
rg --fixed-strings --quiet 'host is required (use host=<deploy-node>)' "$JUSTFILE"

rg --fixed-strings --quiet '/srv/data/syncthing/config' "$SYNCTHING_FILE"
rg --fixed-strings --quiet '/srv/media' "$SYNCTHING_FILE"
rg --fixed-strings --quiet '/srv/data/navidrome' "$NAVIDROME_FILE"
rg --fixed-strings --quiet '/srv/media' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media/inbox/slskd' "$SLSKD_FILE"
rg --fixed-strings --quiet '/srv/media/slskd/incomplete' "$SLSKD_FILE"
