{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.homepage;
  homepageRoute = appCfg.policyServices."admin-homepage";
  listenPort = homepageRoute.origin.port;

  homepageData = import ./data.nix {
    policyServices = appCfg.policyServices;
  };
in
{
  options.services.admin.homepage.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Homepage Dashboard wiring.";
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.homepage-dashboard = {
      enable = true;
      openFirewall = false;
      inherit listenPort;
      allowedHosts = "localhost:${toString listenPort},127.0.0.1:${toString listenPort},${homepageRoute.publicHost}";
      inherit (homepageData)
        settings
        widgets
        services
        bookmarks
        ;
    };
  };
}
