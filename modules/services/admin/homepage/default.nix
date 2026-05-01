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
  hasHomepageAuthEnv = lib.hasAttrByPath [ "sops" "templates" "homepage-auth.env" "path" ] config;

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
    assertions = [
      {
        assertion = hasHomepageAuthEnv;
        message = "Homepage service requires sops template homepage-auth.env for authenticated widget credentials.";
      }
    ];

    services.homepage-dashboard = {
      enable = true;
      openFirewall = false;
      inherit listenPort;
      allowedHosts = "localhost:${toString listenPort},127.0.0.1:${toString listenPort},${homepageRoute.publicHost}";
      environmentFiles = [
        config.sops.templates."homepage-auth.env".path
      ];
      inherit (homepageData)
        settings
        widgets
        services
        bookmarks
        ;
    };
  };
}
