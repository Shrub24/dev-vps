{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.applications.music;
  globals = import ../../policy/globals.nix;
  secretHelpers = import ../../lib/secrets.nix { inherit lib; };

  mediaPermissionReconcile = pkgs.writeShellApplication {
    name = "media-permission-reconcile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.acl
    ];
    text = ''
      set -euo pipefail

      INBOX_DIR=${cfg.inboxDir}
      LIBRARY_DIR=${cfg.libraryDir}
      QUARANTINE_DIR=${cfg.quarantineDir}

      fixup_dir() {
        local dir="$1"
        local write_group="$2"
        local read_group="$3"

        if [[ ! -d "$dir" ]]; then
          return 0
        fi

        find "$dir" -type d -exec chgrp "$write_group" {} +
        find "$dir" -type d -exec chmod 2775 {} +
        find "$dir" -type f -exec chgrp "$write_group" {} +
        find "$dir" -type f -exec chmod 0664 {} +

        setfacl -R -m "g:$write_group:rwx" "$dir"
        find "$dir" -type d -exec setfacl -m "d:g:$write_group:rwX" {} +
        setfacl -R -m "g:$read_group:r-X" "$dir"
        find "$dir" -type d -exec setfacl -m "d:g:$read_group:r-X" {} +

        setfacl -R -m u:syncthing:rwx "$dir"
        find "$dir" -type d -exec setfacl -m d:u:syncthing:rwx {} +
      }

      fixup_dir "$INBOX_DIR" "music-ingest" "media"
      fixup_dir "$LIBRARY_DIR" "music-ingest" "media"
      fixup_dir "$QUARANTINE_DIR" "music-ingest" "media"
    '';
  };
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
    enable = lib.mkEnableOption "music application composition";

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = globals.applications.music.dataRoot;
      description = "Top-level data root for music application services.";
    };

    mediaRoot = lib.mkOption {
      type = lib.types.str;
      default = globals.applications.music.mediaRoot;
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

    secretFiles.host = secretHelpers.mkSecretFileOption "music-host-secrets";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (secretHelpers.mkRequiredSecretAssertion {
        enable = cfg.enable;
        file = cfg.secretFiles.host;
        feature = "applications.music";
        label = "secretFiles.host";
      })
    ];

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
      folderTargets = lib.mapAttrs (
        _name: folder:
        folder
        // {
          ensureDir = false;
        }
      ) cfg.syncthingFolders;
    };

    services.state-backups.services.syncthing = {
      enable = true;
      mode = "live";
      paths = [ "${cfg.dataRoot}/syncthing" ];
    };

    services.navidrome = {
      libraryDir = cfg.libraryDir;
      quarantineDir = cfg.quarantineDir;
      dataDir = "${cfg.dataRoot}/navidrome";
    };

    services.state-backups.services.navidrome = {
      enable = true;
      mode = "live";
      paths = [ "${cfg.dataRoot}/navidrome" ];
    };

    services.beets-inbox = {
      dataDir = "${cfg.dataRoot}/beets";
      mediaRoot = cfg.mediaRoot;
      inboxDir = cfg.inboxDir;
      libraryDir = cfg.libraryDir;
      quarantineDir = cfg.quarantineDir;
      secretFiles.host = cfg.secretFiles.host;
    };

    services.state-backups.services.beets = {
      enable = true;
      mode = "live";
      paths = [ "${cfg.dataRoot}/beets" ];
    };

    services.state-backups.services.media = {
      enable = true;
      mode = "live";
      paths = [ cfg.mediaRoot ];
      exclude = [
        cfg.versionArchiveRoot
        "${cfg.mediaRoot}/.stversions"
      ];
    };

    systemd.paths.beets-inbox-watch.enable = false;
    systemd.paths.beets-quarantine-promote-watch.enable = false;
    systemd.timers.beets-inbox-backstop.enable = false;
    systemd.timers.beets-quarantine-promote-backstop.enable = false;

    services.slskd = {
      downloadsPath = "${cfg.mediaRoot}/inbox/slskd";
      incompletePath = "${cfg.mediaRoot}/slskd-incomplete";
      domain = "oci-melb-1";
      secretFiles.host = cfg.secretFiles.host;
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
      secretFiles.host = cfg.secretFiles.host;
      conservativeDefaults = {
        metadataFallbackSource = "discogs";
        disableBroadRepairJobs = true;
        controlPlaneOnly = true;
      };
    };

    services.state-backups.services.soulsync = lib.mkIf config.services.soulsync.enable {
      enable = true;
      mode = "live";
      paths = [ "${cfg.dataRoot}/soulsync" ];
    };

    services.tagr = {
      enable = true;
      dataDir = "${cfg.dataRoot}/tagr";
      mediaRoot = cfg.mediaRoot;
      secretFiles.host = cfg.secretFiles.host;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaRoot} 0755 root root - -"
      "z ${cfg.mediaRoot} 0755 root root - -"
      "d ${cfg.versionArchiveRoot} 2775 root media - -"
      "d ${cfg.versionArchiveRoot}/library 2775 root media - -"
      "d ${cfg.versionArchiveRoot}/quarantine 2775 root media - -"
      "d ${cfg.libraryDir} 2775 root music-ingest - -"
      "a+ ${cfg.libraryDir} - - - - group:music-ingest:rwX"
      "a+ ${cfg.libraryDir} - - - - default:group:music-ingest:rwX"
      "a+ ${cfg.libraryDir} - - - - group:media:r-X"
      "a+ ${cfg.libraryDir} - - - - default:group:media:r-X"
      "d ${cfg.quarantineDir} 2775 root music-ingest - -"
      "a+ ${cfg.quarantineDir} - - - - group:music-ingest:rwX"
      "a+ ${cfg.quarantineDir} - - - - default:group:music-ingest:rwX"
      "a+ ${cfg.quarantineDir} - - - - group:media:r-X"
      "a+ ${cfg.quarantineDir} - - - - default:group:media:r-X"
      "d ${cfg.inboxDir} 2775 root music-ingest - -"
      "z ${cfg.inboxDir} 2775 root music-ingest - -"
      "a+ ${cfg.inboxDir} - - - - group:music-ingest:rwX"
      "a+ ${cfg.inboxDir} - - - - default:group:music-ingest:rwX"
      "a+ ${cfg.inboxDir} - - - - group:media:r-X"
      "a+ ${cfg.inboxDir} - - - - default:group:media:r-X"
      "f /var/lib/slskd/environment 0640 slskd slskd - -"
      "f /var/lib/tagr/environment 0640 root root - -"
    ];

    systemd.services.media-permission-reconcile = {
      description = "Reconcile media directory ACLs and POSIX permissions recursively";
      after = [ "systemd-tmpfiles-setup.service" ];
      unitConfig.RequiresMountsFor = [ cfg.mediaRoot ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${mediaPermissionReconcile}/bin/media-permission-reconcile";
      };
    };
  };
}
