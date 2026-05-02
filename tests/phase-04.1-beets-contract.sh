#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --raw "$BASE.services.beets-inbox.dataDir" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.services.beets-inbox.mediaRoot" >/dev/null
echo "phase-04.1-beets-contract: PASS"
