{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.niks3-push;
in
{
  options.services.niks3-push = {
    enable = lib.mkEnableOption "post-deploy push of system closures to niks3 sovereign cache";

    hostSecretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Host-scoped SOPS file containing niks3 API push token.";
    };

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:5751";
      description = "niks3 server URL for push operations.";
    };

    cacheName = lib.mkOption {
      type = lib.types.str;
      default = "nix-cache";
      description = "niks3 cache name configured on the server.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.niks3 ];

    sops.secrets = lib.mkIf (cfg.hostSecretFile != null) {
      niks3_push_token = {
        sopsFile = cfg.hostSecretFile;
        key = "niks3/api_token";
        mode = "0400";
      };
    };

    systemd.paths.niks3-push-watch = {
      wantedBy = [ "paths.target" ];
      pathConfig = {
        PathChanged = "/run/current-system";
        Unit = "niks3-push.service";
      };
    };

    systemd.timers.niks3-push-backstop = {
      description = "Backstop timer for niks3 post-deploy push";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "30m";
        Persistent = true;
        Unit = "niks3-push.service";
      };
    };

    systemd.services.niks3-push = {
      description = "Push current system closure to niks3 sovereign cache";
      path = [ pkgs.niks3 ];

      serviceConfig = {
        Type = "oneshot";
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/run" ];
      };

      environment = {
        NIK3_SERVER = cfg.serverUrl;
        NIK3_CACHE = cfg.cacheName;
        NIK3_TOKEN = lib.mkIf (cfg.hostSecretFile != null)
          "$(cat /run/secrets/niks3_push_token)";
      };

      script = ''
        set -euo pipefail
        exec niks3 push --token "$NIK3_TOKEN" --cache "$NIK3_CACHE" "$NIK3_SERVER" /run/current-system
      '';
    };
  };
}
