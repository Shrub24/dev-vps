{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.filebrowser;
  filebrowserRoute = appCfg.policyServices."filebrowser-admin";
  listenAddress = filebrowserRoute.origin.host;
  listenPort = filebrowserRoute.origin.port;
in
{
  options.services.admin.filebrowser.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Filebrowser service wiring.";
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.filebrowser = {
      enable = true;
      openFirewall = false;
      settings = {
        address = listenAddress;
        port = listenPort;
        root = "${appCfg.dataRoot}/filebrowser";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${appCfg.dataRoot}/filebrowser 0750 root root - -"
    ];
  };
}
