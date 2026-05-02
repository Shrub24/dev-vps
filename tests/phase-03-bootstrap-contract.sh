#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --raw "$BASE.networking.hostName" >/dev/null
nix eval --no-write-lock-file --raw "$BASE.disko.devices.disk.main.device" >/dev/null
nix eval --no-write-lock-file "$BASE.boot.loader.grub.configurationLimit" >/dev/null
echo "phase-03-bootstrap-contract: PASS"
