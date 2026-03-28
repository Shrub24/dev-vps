#!/usr/bin/env bash
set -euo pipefail

TAILSCALE_FILE="modules/services/tailscale.nix"
TERMIX_FILE="modules/services/termix.nix"
ADMIN_APP_FILE="modules/applications/admin.nix"
HOST_FILE="hosts/oci-melb-1/default.nix"
USERS_FILE="hosts/oci-melb-1/users.nix"
OCI_PROVIDER_FILE="modules/providers/oci/default.nix"
NAVIDROME_FILE="modules/services/navidrome.nix"
SLSKD_FILE="modules/services/slskd.nix"
JUSTFILE="justfile"
OPERATIONS_FILE=".planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md"
BREAKGLASS_FILE=".planning/phases/03-oci-host-bring-up-and-private-operations/03-BREAKGLASS.md"

rg --fixed-strings --quiet 'services.tailscale = {' "$TAILSCALE_FILE"
rg --fixed-strings --quiet 'enable = true;' "$TAILSCALE_FILE"
rg --fixed-strings --quiet 'openFirewall = false;' "$TAILSCALE_FILE"

rg --fixed-strings --quiet '../../modules/applications/admin.nix' "$HOST_FILE"
rg --fixed-strings --quiet 'modules/services/termix.nix' "$ADMIN_APP_FILE"
rg --fixed-strings --quiet '/srv/data/termix' "$TERMIX_FILE"
rg --fixed-strings --quiet 'ports = [' "$TERMIX_FILE"
rg --fixed-strings --quiet '"8083:8080"' "$TERMIX_FILE"

if rg --fixed-strings --quiet 'networking.firewall.allowedTCPPorts' "$TERMIX_FILE"; then
  echo 'termix module introduced explicit public firewall opening'
  exit 1
fi

if rg --fixed-strings --quiet '8083' "$HOST_FILE"; then
  echo 'termix port leaked into host-level firewall surface'
  exit 1
fi

rg --fixed-strings --quiet 'trustedInterfaces = [ "tailscale0" ]' "$HOST_FILE"
rg --fixed-strings --quiet 'allowedTCPPorts = [ 22 ];' "$HOST_FILE"

rg --fixed-strings --quiet 'users.mutableUsers = false;' "$USERS_FILE"
rg --fixed-strings --quiet 'sshKeys = [' "$USERS_FILE"
rg --fixed-strings --quiet 'users.users.dev.openssh.authorizedKeys.keys = sshKeys;' "$USERS_FILE"
rg --fixed-strings --quiet 'users.users.root.openssh.authorizedKeys.keys = sshKeys;' "$USERS_FILE"

rg --fixed-strings --quiet 'boot.kernelParams = [ "console=ttyAMA0,115200n8" ];' "$OCI_PROVIDER_FILE"
rg --fixed-strings --quiet 'systemd.services."serial-getty@ttyAMA0" = {' "$OCI_PROVIDER_FILE"
rg --fixed-strings --quiet 'wantedBy = [ "multi-user.target" ];' "$OCI_PROVIDER_FILE"

rg --fixed-strings --quiet 'openFirewall = false;' "$NAVIDROME_FILE"
rg --fixed-strings --quiet 'openFirewall = false;' "$SLSKD_FILE"

rg --fixed-strings --quiet 'breakglass-baseline:' "$JUSTFILE"
rg --fixed-strings --quiet 'nix-env -p /nix/var/nix/profiles/system --list-generations' "$JUSTFILE"
rg --fixed-strings --quiet 'derive-host-age host=target_host port="22" key_alias="oci_melb_1_age" sops_file=".sops.yaml" update="false":' "$JUSTFILE"
rg --fixed-strings --quiet 'ssh-keyscan -p "{{port}}" -t ed25519 "{{host}}"' "$JUSTFILE"
rg --fixed-strings --quiet 'Preview only. Re-run with update=true to write to {{sops_file}} anchor &{{key_alias}}.' "$JUSTFILE"

rg --fixed-strings --quiet 'just breakglass-baseline' "$OPERATIONS_FILE"
rg --fixed-strings --quiet '03-BREAKGLASS.md' "$OPERATIONS_FILE"

rg --fixed-strings --quiet 'just derive-host-age host=<target-ip-or-dns>' ".planning/phases/02-oci-bootstrap-and-service-readiness/02-SECRETS-BOOTSTRAP.md"
rg --fixed-strings --quiet 'just derive-host-age host=<target-ip-or-dns> update=true' ".planning/phases/02-oci-bootstrap-and-service-readiness/02-SECRETS-BOOTSTRAP.md"

rg --fixed-strings --quiet '**serial console**' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '`modules/providers/oci/default.nix`' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '`boot.kernelParams = [ "console=ttyAMA0,115200n8" ];`' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '`systemd.services."serial-getty@ttyAMA0"`' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '`hosts/oci-melb-1/users.nix`' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '`openssh.authorizedKeys.keys = sshKeys;`' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '`users.mutableUsers = false;`' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'nix-env -p /nix/var/nix/profiles/system --list-generations' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet '/nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'sudo systemctl restart tailscaled' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'sudo tailscale status' "$BREAKGLASS_FILE"
rg --fixed-strings --quiet 'just tailscale-status' "$BREAKGLASS_FILE"

rg --fixed-strings --quiet 'declared console and key contracts in `03-BREAKGLASS.md`' "$OPERATIONS_FILE"
