#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --raw "$BASE.services.beets-inbox.libraryDir" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.services.beets-inbox.quarantineDir" >/dev/null
echo "phase-04.2-beets-promotion-contract: PASS"
