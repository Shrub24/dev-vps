#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --raw "$BASE.networking.hostName" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.system.stateVersion" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.applications.music.enable" >/dev/null
echo "phase-02-03-host-contract: PASS"
