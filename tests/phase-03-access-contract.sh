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
rg --fixed-strings --quiet 'tailscale-serve-termix' "$ADMIN_APP_FILE"
rg --fixed-strings --quiet 'tailscale serve --yes --bg --https=8443 http://127.0.0.1:8083' "$ADMIN_APP_FILE"
rg --fixed-strings --quiet 'tailscale serve --https=8443 off' "$ADMIN_APP_FILE"
rg --fixed-strings --quiet 'http://127.0.0.1:8083' "$ADMIN_APP_FILE"
rg --fixed-strings --quiet '/srv/data/termix' "$TERMIX_FILE"
rg --fixed-strings --quiet 'ghcr.io/lukegus/termix:latest' "$TERMIX_FILE"
rg --fixed-strings --quiet '/srv/data/termix/data:/app/data' "$TERMIX_FILE"
rg --fixed-strings --quiet 'GUACD_HOST = "127.0.0.1";' "$TERMIX_FILE"
rg --fixed-strings --quiet 'GUACD_PORT = "4822";' "$TERMIX_FILE"
rg --fixed-strings --quiet 'ports = [' "$TERMIX_FILE"
rg --fixed-strings --quiet '"127.0.0.1:8083:8080"' "$TERMIX_FILE"

if rg --fixed-strings --quiet 'tailscale serve' "$TAILSCALE_FILE"; then
	echo 'tailscale service module must remain serve-agnostic'
	exit 1
fi

if rg --fixed-strings --quiet 'termix-official/termix' "$TERMIX_FILE"; then
	echo 'legacy termix image wiring reintroduced'
	exit 1
fi

if rg --fixed-strings --quiet 'TERMIX_GUACD_' "$TERMIX_FILE"; then
	echo 'legacy termix guacd env contract reintroduced'
	exit 1
fi

if rg --fixed-strings --quiet '/var/lib/termix' "$TERMIX_FILE"; then
	echo 'legacy termix data mount target reintroduced'
	exit 1
fi

if rg --fixed-strings --quiet 'networking.firewall.allowedTCPPorts' "$TERMIX_FILE"; then
	echo 'termix module introduced explicit public firewall opening'
	exit 1
fi

if rg --ignore-case --fixed-strings --quiet 'funnel' "$ADMIN_APP_FILE"; then
	echo 'termix admin layer must not enable tailscale funnel/public ingress'
	exit 1
fi

if rg --fixed-strings --quiet -- '--set-path /termix' "$ADMIN_APP_FILE"; then
	echo 'stale termix path-based serve contract reintroduced in admin module'
	exit 1
fi

if rg --fixed-strings --quiet 'off /termix' "$ADMIN_APP_FILE"; then
	echo 'stale termix path-based serve shutdown contract reintroduced in admin module'
	exit 1
fi

if rg --fixed-strings --quiet 'VITE_BASE_PATH' "$TERMIX_FILE"; then
	echo 'stale termix base-path contract reintroduced in termix module'
	exit 1
fi

if rg --ignore-case --fixed-strings --quiet 'native https' "$ADMIN_APP_FILE"; then
	echo 'termix admin layer must not introduce native termix https wording'
	exit 1
fi

if rg --ignore-case --fixed-strings --quiet 'httpsPort' "$TERMIX_FILE"; then
	echo 'termix module must not enable native https port wiring'
	exit 1
fi

if rg --ignore-case --fixed-strings --quiet 'certFile' "$TERMIX_FILE"; then
	echo 'termix module must not add native tls cert wiring'
	exit 1
fi

if rg --ignore-case --fixed-strings --quiet 'keyFile' "$TERMIX_FILE"; then
	echo 'termix module must not add native tls key wiring'
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
rg --fixed-strings --quiet 'tailscale serve status' "$OPERATIONS_FILE"
rg --fixed-strings --quiet '8443' "$OPERATIONS_FILE"

if rg --fixed-strings --quiet '/termix' "$OPERATIONS_FILE"; then
	echo 'operations runbook reintroduced stale /termix path routing guidance'
	exit 1
fi

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
