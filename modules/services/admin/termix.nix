{ lib, config, ... }:

let
  appCfg = config.applications.admin;
  cfg = config.services.admin.termix;
in
{
  options.services.admin.termix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Termix composition wiring.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/termix";
      description = "Data directory for Termix";
    };

    oidc = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether Termix should enable native OIDC auth wiring.";
      };

      issuerUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Pocket ID issuer URL for Termix auth posture documentation/runtime metadata.";
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional env-file containing Termix OIDC variables (OIDC_CLIENT_ID, OIDC_CLIENT_SECRET, OIDC_AUTHORIZATION_URL, OIDC_TOKEN_URL, etc.).";
      };
    };
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    virtualisation.podman.enable = true;

    virtualisation.oci-containers.containers = {
      guacd = {
        autoStart = true;
        image = "docker.io/guacamole/guacd:1.6.0";
        volumes = [
          "${cfg.dataDir}/guacd:/var/lib/guacd"
        ];
      };

      termix = {
        autoStart = true;
        image = "ghcr.io/lukegus/termix:release-2.1.0";
        dependsOn = [ "guacd" ];
        environment = {
          GUACD_HOST = "127.0.0.1";
          GUACD_PORT = "4822";
        }
        // lib.optionalAttrs cfg.oidc.enabled {
          OIDC_ISSUER_URL = toString cfg.oidc.issuerUrl;
        };
        environmentFiles = lib.optionals (cfg.oidc.environmentFile != null) [
          cfg.oidc.environmentFile
        ];
        labels = lib.optionalAttrs cfg.oidc.enabled {
          "io.shrublab.auth.oidc" = "pocket-id";
          "io.shrublab.auth.oidc.issuer" = toString cfg.oidc.issuerUrl;
        };
        ports = [
          "0.0.0.0:8083:8080"
        ];
        extraOptions = [
          "--dns-search=tail0fe19b.ts.net"
          "--dns=100.100.100.100"
        ];
        volumes = [
          "${cfg.dataDir}/data:/app/data"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 root root - -"
      "d ${cfg.dataDir}/data 0750 root root - -"
      "d ${cfg.dataDir}/guacd 0750 root root - -"
    ];

    systemd.services."podman-guacd" = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.services."podman-termix" = {
      wants = [
        "network-online.target"
        "podman-guacd.service"
      ];
      after = [
        "network-online.target"
        "podman-guacd.service"
      ];
    };

    assertions = [
      {
        assertion = !cfg.oidc.enabled || cfg.oidc.issuerUrl != null;
        message = "services.admin.termix.oidc.issuerUrl must be set when services.admin.termix.oidc.enabled=true.";
      }
      {
        assertion = !cfg.oidc.enabled || cfg.oidc.environmentFile != null;
        message = "services.admin.termix.oidc.environmentFile must be set when services.admin.termix.oidc.enabled=true.";
      }
    ];
  };
}
