{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.gatus;

  webPort = appCfg.policyServices."gatus-admin".origin.port;

  mkEndpoint = serviceName: svc: {
    name = serviceName;
    url = svc.healthUrl;
    interval = "1m";
    conditions = [ "[STATUS] == ${toString svc.health.expectedStatus}" ];
  };

  endpoints = lib.mapAttrsToList mkEndpoint appCfg.policyServices;

  oidcEnabled =
    cfg.oidcEnabled
    && cfg.oidcIssuerUrl != null
    && cfg.oidcEnvironmentFile != null
    && cfg.oidcRedirectUrl != "";

  oidcSettings = lib.optionalAttrs oidcEnabled {
    security.oidc = {
      "issuer-url" = cfg.oidcIssuerUrl;
      "redirect-url" = cfg.oidcRedirectUrl;
      "client-id" = "\${GATUS_OIDC_CLIENT_ID}";
      "client-secret" = "\${GATUS_OIDC_CLIENT_SECRET}";
      scopes = [ "openid" ];
    };
  };
in
{
  options.services.admin.gatus = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Gatus service wiring.";
    };

    oidcEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OIDC block for gatus security configuration.";
    };

    oidcIssuerUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "OIDC issuer URL used by Gatus.";
    };

    oidcRedirectUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "OIDC redirect URL used by Gatus callback.";
    };

    oidcEnvironmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Environment file containing GATUS_OIDC_CLIENT_ID/SECRET values.";
    };
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.gatus = {
      enable = true;
      openFirewall = false;
      environmentFile = cfg.oidcEnvironmentFile;
      settings = {
        web.port = webPort;
        inherit endpoints;
      }
      // oidcSettings;
    };
  };
}
