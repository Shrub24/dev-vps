#!/usr/bin/env bash
set -euo pipefail

FLAKE_FILE="flake.nix"
DO_HOST_FILE="hosts/do-admin-1/default.nix"
DO_BOOTSTRAP_FILE="hosts/do-admin-1/bootstrap-config.nix"
DO_PROVIDER_FILE="modules/providers/digitalocean/default.nix"
DO_DISKO_FILE="modules/storage/disko-single-disk.nix"
JUSTFILE="justfile"
SOPS_FILE=".sops.yaml"

rg --fixed-strings --quiet 'nixosConfigurations.do-admin-1 = nixpkgs.lib.nixosSystem {' "$FLAKE_FILE"
rg --fixed-strings --quiet 'system = "x86_64-linux";' "$FLAKE_FILE"
rg --fixed-strings --quiet './hosts/do-admin-1/default.nix' "$FLAKE_FILE"

rg --fixed-strings --quiet '../../modules/providers/digitalocean/default.nix' "$DO_HOST_FILE"
rg --fixed-strings --quiet '../../modules/storage/disko-single-disk.nix' "$DO_HOST_FILE"
rg --fixed-strings --quiet '../../modules/core/users.nix' "$DO_HOST_FILE"
rg --fixed-strings --quiet 'networking.hostName = "do-admin-1";' "$DO_HOST_FILE"
rg --fixed-strings --quiet 'applications.admin.enable = true;' "$DO_HOST_FILE"
rg --fixed-strings --quiet 'disko.devices.disk.main.device = "/dev/vda";' "$DO_HOST_FILE"
nix eval --no-write-lock-file --apply 'ports: builtins.elem 22 ports' path:.#nixosConfigurations.do-admin-1.config.networking.firewall.allowedTCPPorts | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'dev: dev == "/dev/vda"' path:.#nixosConfigurations.do-admin-1.config.disko.devices.disk.main.device | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.applications.admin.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'svc: builtins.hasAttr "tailscale-serve-termix" svc' path:.#nixosConfigurations.do-admin-1.config.systemd.services | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'svc: builtins.hasAttr "tailscale-serve-cockpit" svc' path:.#nixosConfigurations.do-admin-1.config.systemd.services | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.cockpit.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.webhook.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.ntfy-sh.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.gatus.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.vaultwarden.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.filebrowser.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.homepage-dashboard.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.beszel.hub.enable | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --apply 'hosts: hosts == "localhost:8082,127.0.0.1:8082,admin.shrublab.xyz"' path:.#nixosConfigurations.do-admin-1.config.services.homepage-dashboard.allowedHosts | rg --fixed-strings --quiet 'true'
nix eval --no-write-lock-file --raw path:.#nixosConfigurations.do-admin-1.config.services.termix.dataDir | rg --fixed-strings --quiet '/srv/data/termix'

rg --fixed-strings --quiet 'services.homepage-dashboard = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Glance = [' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Access = [' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Cockpit = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet '"Beszel Hub" = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Caddy = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Tailscale = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Navidrome = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Slskd = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Gatus = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'startUrl = "https://admin.shrublab.xyz/#overview";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'columns = 3;' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'useEqualHeights = true;' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'type = "tailscale";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICEID}}";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'key = "{{HOMEPAGE_VAR_TAILSCALE_API_KEY}}";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'type = "navidrome";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'type = "slskd";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'key = "{{HOMEPAGE_VAR_SLSKD_KEY}}";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://gatus.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://vaultwarden.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://filebrowser.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://ntfy.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'Syncthing = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://syncthing.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'url = "http://oci-melb-1.tail0fe19b.ts.net:8384/";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://music.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://slskd.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://beszel.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://gatus.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://filebrowser.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://music.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'href = "https://slskd.shrublab.xyz";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'url = "http://oci-melb-1.tail0fe19b.ts.net:4533/";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'url = "http://oci-melb-1.tail0fe19b.ts.net:5030/";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'iconsOnly = true;' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'header = false;' 'modules/applications/admin.nix'
rg --fixed-strings --quiet '"0Links" = {' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'tab = "Overview";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'disk = "/";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'tab = "Access";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'icon = "si-oracle";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'icon = "si-digitalocean";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'icon = "si-github";' 'modules/applications/admin.nix'
rg --fixed-strings --quiet 'icon = "si-tailscale";' 'modules/applications/admin.nix'

rg --fixed-strings --quiet 'hostName = "do-admin-1";' "$DO_BOOTSTRAP_FILE"
rg --fixed-strings --quiet 'bootstrapUser = "root";' "$DO_BOOTSTRAP_FILE"
rg --fixed-strings --quiet 'bootstrapDisk = "/dev/vda";' "$DO_BOOTSTRAP_FILE"

rg --fixed-strings --quiet '/virtualisation/digital-ocean-config.nix' "$DO_PROVIDER_FILE"
rg --fixed-strings --quiet 'datasource_list = [' "$DO_PROVIDER_FILE"
rg --fixed-strings --quiet '"Digitalocean"' "$DO_PROVIDER_FILE"
rg --fixed-strings --quiet 'cloud_init_modules = [' "$DO_PROVIDER_FILE"
rg --fixed-strings --quiet 'cloud_config_modules = [' "$DO_PROVIDER_FILE"
rg --fixed-strings --quiet 'cloud_final_modules = [' "$DO_PROVIDER_FILE"
! rg --fixed-strings --quiet 'systemd.network = {' "$DO_PROVIDER_FILE"
! rg --fixed-strings --quiet 'networking.useDHCP = lib.mkForce false;' "$DO_PROVIDER_FILE"
! rg --fixed-strings --quiet 'network.enable = lib.mkForce false;' "$DO_PROVIDER_FILE"
! rg --fixed-strings --quiet '"10-eth0-dhcp"' "$DO_PROVIDER_FILE"
! rg --fixed-strings --quiet '"20-en-dhcp"' "$DO_PROVIDER_FILE"

nix eval --no-write-lock-file --apply 'enabled: enabled == true' path:.#nixosConfigurations.do-admin-1.config.services.openssh.enable | rg --fixed-strings --quiet 'true'

rg --fixed-strings --quiet 'disko.devices.disk.main = {' "$DO_DISKO_FILE"
rg --fixed-strings --quiet 'mountpoint = "/";' "$DO_DISKO_FILE"

rg --fixed-strings --quiet 'bootstrap-preflight host:' "$JUSTFILE"
rg --fixed-strings --quiet 'openssh is disabled' "$JUSTFILE"
rg --fixed-strings --quiet 'firewall does not allow tcp/22' "$JUSTFILE"
rg --fixed-strings --quiet 'missing declarative dev/root SSH keys' "$JUSTFILE"

rg --fixed-strings --quiet '^hosts/do-admin-1/secrets\.ya?ml$' "$SOPS_FILE"
rg --fixed-strings --quiet '*do_admin_1_age' "$SOPS_FILE"
