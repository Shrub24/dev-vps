{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.gatus;

  webAddress = appCfg.policyServices."gatus-admin".origin.host;
  webPort = appCfg.policyServices."gatus-admin".origin.port;

  mkEndpoint = serviceName: svc: {
    name = serviceName;
    url = svc.healthUrl;
    interval = "1m";
    conditions = [ "[STATUS] == ${toString svc.health.expectedStatus}" ];
  };

  endpoints = lib.mapAttrsToList mkEndpoint appCfg.policyServices;
in
{
  options.services.admin.gatus = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Gatus service wiring.";
    };

  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.gatus = {
      enable = true;
      openFirewall = false;
      settings = {
        web.address = webAddress;
        web.port = webPort;
        inherit endpoints;
      };
    };
  };
}
