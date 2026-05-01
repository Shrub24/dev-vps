{
  lib,
  config,
  ...
}:
let
  cfg = config.applications.music;
  hasSoulSyncConfig = lib.hasAttrByPath [
    "sops"
    "templates"
    "soulsync-config.json"
    "path"
  ] config;
  hasSoulSyncEnv = lib.hasAttrByPath [
    "sops"
    "templates"
    "soulsync.env"
    "path"
  ] config;

  hasSlskdEnv = lib.hasAttrByPath [
    "sops"
    "templates"
    "slskd.env"
    "path"
  ] config;

  hasTagrEnv = lib.hasAttrByPath [
    "sops"
    "templates"
    "tagr.env"
    "path"
  ] config;

  optionalSoulSyncEnvTemplates = lib.filter (path: path != null) [
    (
      if
        lib.hasAttrByPath [
          "sops"
          "templates"
          "soulsync-spotify.env"
          "path"
        ] config
      then
        config.sops.templates."soulsync-spotify.env".path
      else
        null
    )
    (
      if
        lib.hasAttrByPath [
          "sops"
          "templates"
          "soulsync-deezer.env"
          "path"
        ] config
      then
        config.sops.templates."soulsync-deezer.env".path
      else
        null
    )
    (
      if
        lib.hasAttrByPath [
          "sops"
          "templates"
          "soulsync-youtube.env"
          "path"
        ] config
      then
        config.sops.templates."soulsync-youtube.env".path
      else
        null
    )
  ];
in
{
  imports = [
    ../../modules/services/syncthing.nix
    ../../modules/services/navidrome.nix
    ../../modules/services/slskd.nix
    ../../modules/services/beets-inbox.nix
    ../../modules/services/soulsync.nix
    ../../modules/services/tagr.nix
  ];

  options.applications.music = {
    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data";
      description = "Top-level data root for music application services.";
    };

    mediaRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/media";
      description = "Top-level media root for music application services.";
    };

    inboxDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/inbox";
      description = "Shared inbox directory composed at the application layer.";
    };

    libraryDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/library";
      description = "Shared library directory composed at the application layer.";
    };

    quarantineDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/quarantine";
      description = "Shared quarantine directory composed at the application layer.";
    };

    versionArchiveRoot = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.mediaRoot}/.versions";
      description = "Media-local root for Syncthing version archives kept outside scanned music trees.";
    };

    syncthingDevices = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        arch = {
          id = "L43OT2A-IULZ4LG-YRFMARJ-EX2CDF3-ZYTXGEX-UGWAYE6-K46I3BA-3KZF2AE";
        };
      };
      description = "Syncthing device map for this application composition.";
    };

    syncthingFolders = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        library = {
          path = cfg.libraryDir;
          type = "sendreceive";
          versioning = {
            type = "staggered";
            params = {
              fsPath = "${cfg.versionArchiveRoot}/library";
            };
          };
          ignorePerms = true;
          ensureDir = true;
          ensureMarker = true;
          ensureAcl = true;
          devices = [ "arch" ];
        };
        quarantine = {
          path = cfg.quarantineDir;
          type = "sendreceive";
          versioning = {
            type = "staggered";
            params = {
              fsPath = "${cfg.versionArchiveRoot}/quarantine";
            };
          };
          ignorePerms = true;
          ensureDir = true;
          ensureMarker = true;
          ensureAcl = true;
          devices = [ "arch" ];
        };
      };
      description = "Syncthing folder map for this application composition.";
    };
  };

  config = {
    users.groups.music-ingest.gid = 990;
    users.groups.media.gid = 987;

    users.users.dev.extraGroups = lib.mkAfter [
      "beets"
      "music-ingest"
      "media"
    ];

    services.syncthing = {
      dataDir = "${cfg.dataRoot}/syncthing";
      configDir = "${cfg.dataRoot}/syncthing/config";
      deviceTargets = cfg.syncthingDevices;
      folderTargets = cfg.syncthingFolders;
    };

    services.navidrome = {
      libraryDir = cfg.libraryDir;
      quarantineDir = cfg.quarantineDir;
      dataDir = "${cfg.dataRoot}/navidrome";
    };

    services.beets-inbox = {
      dataDir = "${cfg.dataRoot}/beets";
      mediaRoot = cfg.mediaRoot;
      inboxDir = cfg.inboxDir;
      libraryDir = cfg.libraryDir;
      quarantineDir = cfg.quarantineDir;
    };

    systemd.paths.beets-inbox-watch.enable = false;
    systemd.paths.beets-quarantine-promote-watch.enable = false;
    systemd.timers.beets-inbox-backstop.enable = false;
    systemd.timers.beets-quarantine-promote-backstop.enable = false;

    services.slskd = {
      downloadsPath = "${cfg.mediaRoot}/inbox/slskd";
      incompletePath = "${cfg.mediaRoot}/slskd-incomplete";
      domain = "oci-melb-1";
      environmentFile =
        if hasSlskdEnv then config.sops.templates."slskd.env".path else "/var/lib/slskd/environment";
    };

    services.soulsync = {
      enable = false;
      dataDir = "${cfg.dataRoot}/soulsync";
      mediaRoot = cfg.mediaRoot;
      downloadPath = "${cfg.mediaRoot}/inbox/slskd";
      transferPath = cfg.libraryDir;
      stagingPath = "${cfg.quarantineDir}/approved";
      unresolvedPath = "${cfg.quarantineDir}/untagged";
      timeZone = config.time.timeZone;
      configTemplateFile =
        if hasSoulSyncConfig then config.sops.templates."soulsync-config.json".path else null;
      environmentFile = if hasSoulSyncEnv then config.sops.templates."soulsync.env".path else null;
      optionalEnvironmentFiles = optionalSoulSyncEnvTemplates;
      conservativeDefaults = {
        metadataFallbackSource = "discogs";
        disableBroadRepairJobs = true;
        controlPlaneOnly = true;
      };
    };

    services.tagr = {
      enable = true;
      dataDir = "${cfg.dataRoot}/tagr";
      mediaRoot = cfg.mediaRoot;
      environmentFile =
        if hasTagrEnv then config.sops.templates."tagr.env".path else "/var/lib/tagr/environment";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaRoot} 0755 root root - -"
      "z ${cfg.mediaRoot} 0755 root root - -"
      "d ${cfg.versionArchiveRoot} 2775 root media - -"
      "d ${cfg.versionArchiveRoot}/library 2775 root media - -"
      "d ${cfg.versionArchiveRoot}/quarantine 2775 root media - -"
      "d ${cfg.libraryDir} 2775 root music-ingest - -"
      "a+ ${cfg.libraryDir} - - - - group:music-ingest:rwx"
      "a+ ${cfg.libraryDir} - - - - default:group:music-ingest:rwX"
      "a+ ${cfg.libraryDir} - - - - group:media:r-X"
      "a+ ${cfg.libraryDir} - - - - default:group:media:r-X"
      "d ${cfg.quarantineDir} 2775 root music-ingest - -"
      "a+ ${cfg.quarantineDir} - - - - group:music-ingest:rwx"
      "a+ ${cfg.quarantineDir} - - - - default:group:music-ingest:rwX"
      "a+ ${cfg.quarantineDir} - - - - group:media:r-X"
      "a+ ${cfg.quarantineDir} - - - - default:group:media:r-X"
      "d ${cfg.inboxDir} 2775 root music-ingest - -"
      "z ${cfg.inboxDir} 2775 root music-ingest - -"
      "f /var/lib/slskd/environment 0640 slskd slskd - -"
      "f /var/lib/tagr/environment 0640 root root - -"
    ];
  };
}
