{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.pocket-id;
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
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
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
