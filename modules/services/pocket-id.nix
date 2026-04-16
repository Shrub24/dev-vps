{
  lib,
  config,
  ...
}:

let
  cfg = config.services.shrublab-pocket-id;
in
{
  options.services.shrublab-pocket-id = {
    enable = lib.mkEnableOption "Shrublab Pocket ID composition";

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

  config = lib.mkIf cfg.enable {
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
