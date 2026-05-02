#!/usr/bin/env bash
set -euo pipefail

BASE='path:.#nixosConfigurations.oci-melb-1.config'
nix eval --no-write-lock-file --raw "$BASE.networking.hostName" >/dev/null
nix eval --no-write-lock-file --apply 'v: v == false' "$BASE.services.tailscale.openFirewall" >/dev/null
nix eval --no-write-lock-file --apply 'v: builtins.elem 22 v' "$BASE.networking.firewall.allowedTCPPorts" >/dev/null
echo "phase-03-access-contract: PASS"
