{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.vaultwarden;
  vaultRoute = appCfg.policyServices."vaultwarden-admin";
  vaultHost = vaultRoute.origin.host;
  vaultPort = vaultRoute.origin.port;
in
{
  options.services.admin.vaultwarden.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Vaultwarden service wiring.";
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      config = {
        ROCKET_ADDRESS = vaultHost;
        ROCKET_PORT = vaultPort;
        SIGNUPS_ALLOWED = false;
      };
    };
  };
}
