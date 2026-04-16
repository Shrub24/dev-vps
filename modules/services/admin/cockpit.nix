{
  lib,
  config,
  pkgs,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.cockpit;
in
{
  options.services.admin.cockpit.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Cockpit module wiring.";
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.cockpit = {
      enable = true;
      openFirewall = false;
      package = pkgs.cockpit;
    };

    environment.systemPackages = [
      pkgs."cockpit-podman"
      pkgs."cockpit-files"
    ];

    services.udisks2.enable = true;
  };
}
