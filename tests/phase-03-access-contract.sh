#!/usr/bin/env bash
set -euo pipefail

TAILSCALE_FILE="modules/services/tailscale.nix"
HOST_FILE="hosts/oci-melb-1/default.nix"
NAVIDROME_FILE="modules/services/navidrome.nix"
SLSKD_FILE="modules/services/slskd.nix"
JUSTFILE="justfile"
OPERATIONS_FILE=".planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md"
BREAKGLASS_FILE=".planning/phases/03-oci-host-bring-up-and-private-operations/03-BREAKGLASS.md"

rg --fixed-strings --quiet 'services.tailscale = {' "$TAILSCALE_FILE"
rg --fixed-strings --quiet 'enable = true;' "$TAILSCALE_FILE"
rg --fixed-strings --quiet 'openFirewall = false;' "$TAILSCALE_FILE"

rg --fixed-strings --quiet 'trustedInterfaces = [ "tailscale0" ]' "$HOST_FILE"

rg --fixed-strings --quiet 'openFirewall = false;' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'openFirewall = false;' "$SLSKD_FILE"

rg --fixed-strings --quiet 'breakglass-baseline:' "$JUSTFILE"
rg --fixed-strings --quiet 'nix-env -p /nix/var/nix/profiles/system --list-generations' "$JUSTFILE"

rg --fixed-strings --quiet 'just breakglass-baseline' "$OPERATIONS_FILE"
rg --fixed-strings --quiet '03-BREAKGLASS.md' "$OPERATIONS_FILE"

rg --fixed-strings --quiet '**serial console**' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'nix-env -p /nix/var/nix/profiles/system --list-generations' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '/nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'sudo systemctl restart tailscaled' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'sudo tailscale status' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'just tailscale-status' "$BREAKGLASS_FILE"
