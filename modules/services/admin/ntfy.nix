{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.ntfy;
  ntfyRoute = appCfg.policyServices."ntfy-admin";
  listenAddress = "${ntfyRoute.origin.host}:${toString ntfyRoute.origin.port}";
  publicBaseUrl = ntfyRoute.publicUrl;
in
{
  options.services.admin.ntfy.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Ntfy service wiring.";
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = publicBaseUrl;
        upstream-base-url = publicBaseUrl;
        behind-proxy = true;
        proxy-forwarded-header = "X-Forwarded-For";
        listen-http = listenAddress;
      };
    };

  };
}
