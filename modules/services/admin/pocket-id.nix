{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.pocket-id;

  mkOidcEndpoints = issuerUrl: {
    issuerUrl = issuerUrl;
    wellknownUrl = "${issuerUrl}/.well-known/openid-configuration";
    authorizationUrl = "${issuerUrl}/authorize";
    tokenUrl = "${issuerUrl}/api/oidc/token";
    userinfoUrl = "${issuerUrl}/api/oidc/userinfo";
  };

  oidc = mkOidcEndpoints cfg.appUrl;
in
{
  options.services.admin.pocket-id = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Pocket ID service wiring.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/pocket-id";
      description = "Persistent data directory for Pocket ID.";
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      description = "Externally reachable Pocket ID URL used as OIDC issuer base.";
    };

    oidc = {
      issuerUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC issuer URL.";
      };

      wellknownUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC well-known URL.";
      };

      authorizationUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC authorization URL.";
      };

      tokenUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC token URL.";
      };

      userinfoUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC userinfo URL.";
      };
    };
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.admin.pocket-id.oidc = oidc;

    services.pocket-id = {
      enable = true;
      dataDir = cfg.dataDir;
      settings = {
        APP_URL = cfg.appUrl;
        TRUST_PROXY = true;
        ENCRYPTION_KEY_FILE = "/run/secrets/pocket-id.encryption_key";
      };
    };
  };
}
