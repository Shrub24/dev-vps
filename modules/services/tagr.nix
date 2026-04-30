{
  lib,
  config,
  ...
}:
let
  cfg = config.services.tagr;
  envDir = builtins.dirOf cfg.environmentFile;
  libraryPath = "${cfg.mediaRoot}/library";
  quarantinePath = "${cfg.mediaRoot}/quarantine";
  ingestGid = toString config.users.groups.music-ingest.gid;
  mediaGid = toString config.users.groups.media.gid;
in
{
  options.services.tagr = {
    enable = lib.mkEnableOption "Tagr manual metadata editor";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/tagr";
      description = "Persistent data directory for Tagr.";
    };

    mediaRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/media";
      description = "Canonical media root used to derive Tagr library and quarantine mounts.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/tagr/environment";
      description = "Environment file containing Tagr auth values.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Listen address for host port mapping.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Tagr web UI port on the host.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 root root - -"
      "d ${envDir} 0750 root root - -"
      "f ${cfg.environmentFile} 0640 root root - -"
    ];

    virtualisation.oci-containers.containers.tagr = {
      autoStart = true;
      image = "ghcr.io/shrub24/tagr:latest";
      ports = [
        "${cfg.listenAddress}:${toString cfg.port}:3000"
      ];
      environment = {
        DATABASE_URL = "file:/data/tagr.db";
        MUSIC_FOLDERS = "/music/library,/music/quarantine";
        PUID = "1001";
        PGID = ingestGid;
      };
      environmentFiles = [
        cfg.environmentFile
      ];
      extraOptions = [
        "--group-add=${ingestGid}"
        "--group-add=${mediaGid}"
      ];
      volumes = [
        "${cfg.dataDir}:/data"
        "${libraryPath}:/music/library:rw"
        "${quarantinePath}:/music/quarantine:rw"
      ];
    };

    systemd.services."podman-tagr" = {
      wants = [
        "network-online.target"
        "syncthing.service"
      ];
      after = [
        "network-online.target"
        "syncthing.service"
      ];
      unitConfig.RequiresMountsFor = [
        cfg.dataDir
        libraryPath
        quarantinePath
        envDir
      ];
      serviceConfig.SupplementaryGroups = lib.mkAfter [
        "music-ingest"
        "media"
      ];
    };
  };
}
