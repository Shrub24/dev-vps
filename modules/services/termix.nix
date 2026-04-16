{ lib, config, ... }:

let
  cfg = config.services.termix;
in
{
  options.services.termix = {
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

  config = {
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
        image = "ghcr.io/lukegus/termix:release-2.0.0";
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

    # Ensure host switch/apply operations also bounce Termix so container runtime
    # picks up host-level edits even when generated unit content doesn't change.
    system.activationScripts.termix-restart-on-switch = {
      deps = [ "etc" ];
      text = ''
        ${config.systemd.package}/bin/systemctl try-restart podman-termix.service || true
      '';
    };

    assertions = [
      {
        assertion = !cfg.oidc.enabled || cfg.oidc.issuerUrl != null;
        message = "services.termix.oidc.issuerUrl must be set when services.termix.oidc.enabled=true.";
      }
      {
        assertion = !cfg.oidc.enabled || cfg.oidc.environmentFile != null;
        message = "services.termix.oidc.environmentFile must be set when services.termix.oidc.enabled=true.";
      }
    ];
  };
}
