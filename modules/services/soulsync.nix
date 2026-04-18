{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.soulsync;
in
{
  options.services.soulsync = {
    enable = lib.mkEnableOption "SoulSync ingest service";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/boulderbadgedad/soulsync:2.3";
      description = "Pinned SoulSync container image.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/soulsync";
      description = "Persistent data directory for SoulSync.";
    };

    mediaRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/media";
      description = "Media root used to derive SoulSync path defaults.";
    };

    downloadPath = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/inbox/slskd";
      description = "Host download path consumed by SoulSync.";
    };

    transferPath = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/library";
      description = "Host transfer/library path used by SoulSync.";
    };

    stagingPath = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/quarantine/approved";
      description = "Host import staging path used by SoulSync.";
    };

    unresolvedPath = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/quarantine/untagged";
      description = "Host unresolved/review path retained for operator fallback flow.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Listen address for SoulSync container port mapping.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8008;
      description = "SoulSync web UI port on the host.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "Timezone passed into SoulSync container.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional env-file with required SoulSync credentials and runtime values.";
    };

    optionalEnvironmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Optional additional env-files (provider-specific) loaded only when present.";
    };

    configTemplateFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional rendered config template copied into dataDir/config.json before container start.";
    };

    conservativeDefaults = {
      metadataFallbackSource = lib.mkOption {
        type = lib.types.enum [
          "deezer"
          "itunes"
          "spotify"
          "discogs"
          "hydrabase"
        ];
        default = "discogs";
        description = "Preferred primary metadata fallback source for rollout defaults.";
      };

      disableBroadRepairJobs = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Conservative rollout guard documented for pre-existing library mutation posture.";
      };

      controlPlaneOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Control-plane-first posture flag for public exposure and playback suppression intent.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 root root - -"
      "d ${cfg.dataDir}/logs 0750 root root - -"
      "d ${cfg.stagingPath} 2775 root music-ingest - -"
      "d ${cfg.unresolvedPath} 2775 root music-ingest - -"
      "a+ ${cfg.unresolvedPath} - - - - group:media:r-x"
      "a+ ${cfg.unresolvedPath} - - - - default:group:media:r-X"
      "a+ ${cfg.stagingPath} - - - - group:media:r-x"
      "a+ ${cfg.stagingPath} - - - - default:group:media:r-X"
    ];

    systemd.services.soulsync-config = lib.mkIf (cfg.configTemplateFile != null) {
      description = "Render SoulSync config from host template";
      wantedBy = [ "multi-user.target" ];
      before = [ "podman-soulsync.service" ];
      after = [ "srv-data.mount" ];
      unitConfig = {
        RequiresMountsFor = [ cfg.dataDir ];
        ConditionPathExists = cfg.configTemplateFile;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "soulsync-config-render" ''
          set -euo pipefail
          install -d -m 0750 "${cfg.dataDir}"
          install -m 0640 "${cfg.configTemplateFile}" "${cfg.dataDir}/config.json"
        '';
      };
    };

    virtualisation.oci-containers.containers.soulsync = {
      autoStart = true;
      image = cfg.image;
      ports = [
        "${cfg.listenAddress}:${toString cfg.port}:8008"
      ];
      environment = {
        FLASK_ENV = "production";
        PYTHONPATH = "/app";
        TZ = cfg.timeZone;
        SOULSYNC_CONFIG_PATH = "/app/data/config.json";
        SOULSYNC_SPOTIFY_CALLBACK_PORT = "8888";
        SOULSYNC_TIDAL_CALLBACK_PORT = "8889";
        SOULSYNC_CONTROL_PLANE_ONLY = if cfg.conservativeDefaults.controlPlaneOnly then "1" else "0";
        SOULSYNC_DISABLE_BROAD_REPAIR_JOBS =
          if cfg.conservativeDefaults.disableBroadRepairJobs then "1" else "0";
        SOULSYNC_METADATA_FALLBACK_SOURCE = cfg.conservativeDefaults.metadataFallbackSource;
      };
      environmentFiles =
        lib.optionals (cfg.environmentFile != null) [ cfg.environmentFile ] ++ cfg.optionalEnvironmentFiles;
      extraOptions = [
        "--dns-search=tail0fe19b.ts.net"
      ];
      volumes = [
        "${cfg.dataDir}:/app/data"
        "${cfg.downloadPath}:${cfg.downloadPath}:rw"
        "${cfg.transferPath}:${cfg.transferPath}:rw"
        "${cfg.stagingPath}:${cfg.stagingPath}:rw"
        "${cfg.unresolvedPath}:${cfg.unresolvedPath}:rw"
      ];
    };

    systemd.services."podman-soulsync" = {
      wants = [
        "network-online.target"
      ]
      ++ lib.optionals (cfg.configTemplateFile != null) [ "soulsync-config.service" ];
      after = [
        "network-online.target"
        "srv-data.mount"
        "srv-media.mount"
      ]
      ++ lib.optionals (cfg.configTemplateFile != null) [ "soulsync-config.service" ];
      requires = [
        "srv-data.mount"
        "srv-media.mount"
      ];
      unitConfig.RequiresMountsFor = [
        cfg.dataDir
        cfg.downloadPath
        cfg.transferPath
        cfg.stagingPath
        cfg.unresolvedPath
      ];
    };
  };
}
