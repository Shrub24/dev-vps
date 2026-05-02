#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.do-admin-1.config'
nix eval --no-write-lock-file --raw "$BASE.networking.hostName" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == true' "$BASE.applications.admin.enable" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.system.stateVersion" >/dev/null
echo "phase-do-admin-contract: PASS"
