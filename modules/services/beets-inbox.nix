{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.beets-inbox;

  mediaInboxDir = if cfg.inboxDir != null then cfg.inboxDir else "${cfg.mediaRoot}/inbox";
  mediaLibraryDir = if cfg.libraryDir != null then cfg.libraryDir else "${cfg.mediaRoot}/library";
  mediaQuarantineDir =
    if cfg.quarantineDir != null then cfg.quarantineDir else "${cfg.mediaRoot}/quarantine";
  mediaUntaggedDir = "${mediaQuarantineDir}/untagged";
  mediaApprovedDir = "${mediaQuarantineDir}/approved";

  pkgsUnstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  beetsRuntime = pkgsUnstable.python3Packages.beets.override {
    pluginOverrides = {
      bandcamp = {
        enable = true;
        propagatedBuildInputs = [ pkgsUnstable.python3Packages.beetcamp ];
      };
    };
  };

  beetsConfig = pkgs.writeText "beets-config.yaml" (
    builtins.readFile ../../scripts/beets-config.yaml
  );

  beetsConfigSource =
    if lib.hasAttrByPath [ "sops" "templates" "beets-config.yaml" "path" ] config then
      config.sops.templates."beets-config.yaml".path
    else
      beetsConfig;

  beetsInboxRunner = pkgs.writeShellApplication {
    name = "beets-inbox-runner";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
    ];
    text = ''
      BEETS_CONFIG_SOURCE=${beetsConfigSource}
      ${builtins.readFile ../../scripts/beets-inbox-runner.sh}
    '';
  };

  beetsQuarantineApprovedRunner = pkgs.writeShellApplication {
    name = "beets-quarantine-approved-runner";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
    ];
    text = ''
      BEETS_CONFIG_SOURCE=${beetsConfigSource}
      ${builtins.readFile ../../scripts/beets-inbox-runner.sh}
    '';
  };

  beetsPermissionReconcile = pkgs.writeShellApplication {
    name = "beets-permission-reconcile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.acl
    ];
    text = ''
      set -euo pipefail

      LIBRARY_ROOT=${mediaLibraryDir}
      QUARANTINE_ROOT=${mediaQuarantineDir}
      UNTAGGED_ROOT=${mediaUntaggedDir}
      APPROVED_ROOT=${mediaApprovedDir}

      if [[ -d "$LIBRARY_ROOT" ]]; then
        find "$LIBRARY_ROOT" -type d -exec chgrp media {} +
        find "$LIBRARY_ROOT" -type d -exec chmod 2775 {} +
        find "$LIBRARY_ROOT" -type f -exec chgrp media {} +
        find "$LIBRARY_ROOT" -type f -exec chmod 0664 {} +
      fi

      if [[ -d "$QUARANTINE_ROOT" ]]; then
        find "$QUARANTINE_ROOT" -type d -exec chgrp music-ingest {} +
        find "$QUARANTINE_ROOT" -type d -exec chmod 2775 {} +
        find "$QUARANTINE_ROOT" -type f -exec chgrp music-ingest {} +
        find "$QUARANTINE_ROOT" -type f -exec chmod 0664 {} +
        setfacl -R -m g:media:r-x "$QUARANTINE_ROOT"
        find "$QUARANTINE_ROOT" -type d -exec setfacl -m d:g:media:r-X {} +
      fi

      if [[ -d "$UNTAGGED_ROOT" ]]; then
        setfacl -R -m g:media:r-x "$UNTAGGED_ROOT"
        find "$UNTAGGED_ROOT" -type d -exec setfacl -m d:g:media:r-X {} +
      fi

      if [[ -d "$APPROVED_ROOT" ]]; then
        setfacl -R -m g:media:r-x "$APPROVED_ROOT"
        find "$APPROVED_ROOT" -type d -exec setfacl -m d:g:media:r-X {} +
      fi
    '';
  };
in
{
  options.services.beets-inbox.dataDir = lib.mkOption {
    type = lib.types.str;
    default = "/srv/data/beets";
    description = "Data directory for beets-inbox";
  };

  options.services.beets-inbox.mediaRoot = lib.mkOption {
    type = lib.types.str;
    default = "/srv/media";
    description = "Root directory for media paths";
  };

  options.services.beets-inbox.inboxDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Optional full path for inbox directory (defaults to mediaRoot + /inbox).";
  };

  options.services.beets-inbox.libraryDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Optional full path for library directory (defaults to mediaRoot + /library).";
  };

  options.services.beets-inbox.quarantineDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Optional full path for quarantine root (always creates fixed untagged/approved subdirs).";
  };

  config = {
    users.groups.beets = { };
    users.users.beets = {
      isSystemUser = true;
      group = "beets";
      home = cfg.dataDir;
      createHome = false;
      extraGroups = [
        "music-ingest"
        "media"
      ];
    };

    environment.systemPackages = [
      beetsRuntime
      beetsInboxRunner
      beetsQuarantineApprovedRunner
      beetsPermissionReconcile
    ];

    systemd.tmpfiles.rules = [
      "d ${config.services.beets-inbox.dataDir} 0750 beets beets - -"
      "d ${config.services.beets-inbox.dataDir}/state 0750 beets beets - -"
      "d ${config.services.beets-inbox.dataDir}/logs 0750 beets beets - -"
      "a+ ${config.services.beets-inbox.dataDir}/logs - - - - user:dev:r-x"
      "a+ ${config.services.beets-inbox.dataDir}/logs - - - - default:user:dev:r-x"
      "d ${mediaLibraryDir} 2775 root media - -"
      "d ${mediaQuarantineDir} 2775 root music-ingest - -"
      "d ${mediaUntaggedDir} 2775 root music-ingest - -"
      "d ${mediaApprovedDir} 2775 root music-ingest - -"
      "a+ ${mediaUntaggedDir} - - - - group:media:r-x"
      "a+ ${mediaUntaggedDir} - - - - default:group:media:r-X"
      "a+ ${mediaApprovedDir} - - - - group:media:r-x"
      "a+ ${mediaApprovedDir} - - - - default:group:media:r-X"
    ];

    systemd.services.beets-inbox-run = {
      description = "Beets all-inbox native album import worker";
      unitConfig.RequiresMountsFor = [
        config.services.beets-inbox.dataDir
        cfg.mediaRoot
        mediaInboxDir
        mediaLibraryDir
        mediaUntaggedDir
        mediaApprovedDir
      ];
      unitConfig.ConditionPathIsDirectory = mediaInboxDir;
      after = [
        "srv-data.mount"
        "srv-media.mount"
        "systemd-tmpfiles-setup.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "beets";
        Group = "beets";
        SupplementaryGroups = [
          "music-ingest"
          "media"
        ];
        WorkingDirectory = cfg.dataDir;
        Environment = "BEETSDIR=${cfg.dataDir}";
        ExecStart = "${beetsInboxRunner}/bin/beets-inbox-runner ${mediaInboxDir}";
        ExecStartPost = [ "+${beetsPermissionReconcile}/bin/beets-permission-reconcile" ];
        UMask = "0002";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectClock = true;
        ProtectProc = "invisible";
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        ReadWritePaths = [
          cfg.dataDir
          mediaInboxDir
          mediaLibraryDir
          mediaUntaggedDir
          mediaApprovedDir
        ];
      };
    };

    systemd.services.beets-quarantine-promote-run = {
      description = "Beets quarantine approved promotion worker";
      unitConfig.RequiresMountsFor = [
        cfg.dataDir
        cfg.mediaRoot
        mediaLibraryDir
        mediaApprovedDir
      ];
      unitConfig.ConditionPathIsDirectory = mediaApprovedDir;
      after = [
        "srv-data.mount"
        "srv-media.mount"
        "systemd-tmpfiles-setup.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "beets";
        Group = "beets";
        SupplementaryGroups = [
          "music-ingest"
          "media"
        ];
        WorkingDirectory = cfg.dataDir;
        Environment = "BEETSDIR=${cfg.dataDir}";
        ExecStart = "${beetsQuarantineApprovedRunner}/bin/beets-quarantine-approved-runner ${mediaApprovedDir}";
        ExecStartPost = [ "+${beetsPermissionReconcile}/bin/beets-permission-reconcile" ];
        UMask = "0002";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectClock = true;
        ProtectProc = "invisible";
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        ReadWritePaths = [
          cfg.dataDir
          mediaLibraryDir
          mediaApprovedDir
        ];
      };
    };

    systemd.paths.beets-inbox-watch = {
      enable = false;
      unitConfig.RequiresMountsFor = [
        cfg.mediaRoot
        mediaInboxDir
      ];
      after = [ "srv-media.mount" ];
      pathConfig.PathModified = mediaInboxDir;
      pathConfig.Unit = "beets-inbox-run.service";
    };

    systemd.paths.beets-quarantine-promote-watch = {
      enable = false;
      unitConfig.RequiresMountsFor = [
        cfg.mediaRoot
        mediaApprovedDir
      ];
      after = [ "srv-media.mount" ];
      pathConfig.PathModified = mediaApprovedDir;
      pathConfig.Unit = "beets-quarantine-promote-run.service";
    };

    systemd.timers.beets-inbox-backstop = {
      enable = false;
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "15m";
        Unit = "beets-inbox-run.service";
      };
    };

    systemd.timers.beets-quarantine-promote-backstop = {
      enable = false;
      timerConfig = {
        OnBootSec = "10m";
        OnUnitActiveSec = "20m";
        Unit = "beets-quarantine-promote-run.service";
      };
    };
  };
}
