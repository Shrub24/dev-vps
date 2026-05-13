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
  options.services.admin.ntfy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Ntfy service wiring.";
    };

    firebaseKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to Firebase Admin SDK key file for Firebase Cloud Messaging (FCM)
        push notifications on Android. When set, `firebase-key-file` is added to
        the ntfy server config. See https://ntfy.sh/docs/config/#firebase-fcm.
      '';
    };
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
      } // lib.optionalAttrs (cfg.firebaseKeyFile != null) {
        "firebase-key-file" = cfg.firebaseKeyFile;
      };
    };

  };
}
