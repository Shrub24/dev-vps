#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.services.syncthing.enable" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == false' "$BASE.services.syncthing.openDefaultPorts" >/dev/null
nix eval --no-write-lock-file --apply 'v: v != {}' "$BASE.services.syncthing.settings.folders" >/dev/null
echo "phase-04-syncthing-contract: PASS"
