{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/profiles/base-server.nix
    ../../modules/profiles/worker-interface.nix
    ../../modules/applications/admin/default.nix
    ../../modules/applications/edge-ingress.nix
    ../../modules/providers/digitalocean/default.nix
    ../../modules/storage/disko-single-disk.nix
    ../../modules/core/users.nix
    ./secrets.nix
    ./quantum.nix
    ./edge.nix
    ./networking.nix
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "do-admin-1";
  disko.devices.disk.main.device = "/dev/vda";
  disko-root-extra = "100%";
  applications.admin.enable = true;
  applications.admin.dataRoot = "/srv/data";
  services.beszel-agent-auth = {
    enable = true;
    tokenSopsFile = ../../hosts/do-admin-1/secrets.yaml;
  };

  systemd.tmpfiles.rules = [
    "d ${config.applications.admin.dataRoot} 0755 root root - -"
    "z ${config.applications.admin.dataRoot} 0755 root root - -"
    "a+ ${config.applications.admin.dataRoot} - - - - user:dev:r-X"
    "a+ ${config.applications.admin.dataRoot} - - - - default:user:dev:r-X"
  ];

  systemd.services.admin-dev-data-access-reconcile = {
    description = "Reconcile dev read/traverse access on admin data root";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "admin-dev-data-access-reconcile" ''
        set -euo pipefail
        if [ -d "${config.applications.admin.dataRoot}" ]; then
          ${pkgs.acl}/bin/setfacl -m u:dev:rX "${config.applications.admin.dataRoot}"
          find "${config.applications.admin.dataRoot}" -xdev -type d ! -path "${config.applications.admin.dataRoot}/quantum/mnt" ! -path "${config.applications.admin.dataRoot}/quantum/mnt/*" -exec ${pkgs.acl}/bin/setfacl -m d:u:dev:rX {} +
        fi
      '';
    };
  };

  system.stateVersion = "25.11";
}
