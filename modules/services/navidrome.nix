{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.navidrome;
  libraryDir = if cfg.libraryDir != null then cfg.libraryDir else "${cfg.mediaRoot}/library";
  quarantineDir =
    if cfg.quarantineDir != null then cfg.quarantineDir else "${cfg.mediaRoot}/quarantine";
in
{
  options.services.navidrome.mediaRoot = lib.mkOption {
    type = lib.types.str;
    default = "/srv/media";
    description = "Root directory for media files";
  };

  options.services.navidrome.dataDir = lib.mkOption {
    type = lib.types.str;
    default = "/srv/data/navidrome";
    description = "Data directory for Navidrome";
  };

  options.services.navidrome.libraryDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Primary Navidrome library path (defaults to mediaRoot + /library).";
  };

  options.services.navidrome.quarantineDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Secondary Navidrome library path for quarantine (defaults to mediaRoot + /quarantine).";
  };

  config = {
    services.navidrome = {
      enable = true;
      openFirewall = false;
      settings = {
        # This is the default library. Additional libraries are managed by
        # Navidrome's multi-library feature.
        MusicFolder = lib.mkDefault libraryDir;
        DataFolder = lib.mkDefault config.services.navidrome.dataDir;
        ScanSchedule = "15m";
        EnableTranscodingConfig = true;
        DefaultDownsamplingFormat = "opus";
        TranscodingCacheSize = "2GB";
        FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
        Address = "0.0.0.0";
      };
    };

    systemd.tmpfiles.settings.navidromeDirs = lib.mkForce {
      "${cfg.settings.DataFolder or "/var/lib/navidrome"}"."d" = {
        mode = "700";
        user = cfg.user;
        group = cfg.group;
      };
      "${cfg.settings.CacheFolder or "/var/lib/navidrome/cache"}"."d" = {
        mode = "700";
        user = cfg.user;
        group = cfg.group;
      };
    };

    systemd.services.navidrome = {
      unitConfig.RequiresMountsFor = [
        libraryDir
        quarantineDir
        cfg.dataDir
      ];
      wants = [
        "network-online.target"
        "syncthing.service"
      ];
      after = [
        "srv-data.mount"
        "srv-media.mount"
        "network-online.target"
        "syncthing.service"
      ];
      serviceConfig.ReadWritePaths = lib.mkAfter [
        libraryDir
        quarantineDir
      ];
      serviceConfig.PrivateMounts = lib.mkForce false;
      serviceConfig.SupplementaryGroups = lib.mkAfter [
        "media"
        "music-ingest"
      ];
    };
  };
}
