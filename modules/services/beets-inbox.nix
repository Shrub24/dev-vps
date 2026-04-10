{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  pkgsUnstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  beetsRuntime = import ./beets-inbox-runtime.nix {
    inherit pkgsUnstable;
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

      LIBRARY_ROOT=/srv/media/library
      QUARANTINE_ROOT=/srv/media/quarantine
      UNTAGGED_ROOT=/srv/media/quarantine/untagged
      APPROVED_ROOT=/srv/media/quarantine/approved

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
  users.groups.beets = { };
  users.users.beets = {
    isSystemUser = true;
    group = "beets";
    home = "/srv/data/beets";
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
    "d /srv/data/beets 0750 beets beets - -"
    "d /srv/data/beets/state 0750 beets beets - -"
    "d /srv/data/beets/logs 0750 beets beets - -"
    "a+ /srv/data/beets/logs - - - - user:dev:r-x"
    "a+ /srv/data/beets/logs - - - - default:user:dev:r-x"
    "d /srv/media/library 2775 root media - -"
    "d /srv/media/quarantine 2775 root music-ingest - -"
    "d /srv/media/quarantine/untagged 2775 root music-ingest - -"
    "d /srv/media/quarantine/approved 2775 root music-ingest - -"
    "a+ /srv/media/quarantine/untagged - - - - group:media:r-x"
    "a+ /srv/media/quarantine/untagged - - - - default:group:media:r-X"
    "a+ /srv/media/quarantine/approved - - - - group:media:r-x"
    "a+ /srv/media/quarantine/approved - - - - default:group:media:r-X"
  ];

  systemd.services.beets-inbox-run = {
    description = "Beets all-inbox native album import worker";
    unitConfig.RequiresMountsFor = [
      "/srv/data/beets"
      "/srv/media"
      "/srv/media/inbox"
      "/srv/media/library"
      "/srv/media/quarantine/untagged"
      "/srv/media/quarantine/approved"
    ];
    unitConfig.ConditionPathIsDirectory = "/srv/media/inbox";
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
      WorkingDirectory = "/srv/data/beets";
      Environment = "BEETSDIR=/srv/data/beets";
      ExecStart = "${beetsInboxRunner}/bin/beets-inbox-runner /srv/media/inbox";
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
        "/srv/data/beets"
        "/srv/media/inbox"
        "/srv/media/library"
        "/srv/media/quarantine/untagged"
        "/srv/media/quarantine/approved"
      ];
    };
  };

  systemd.services.beets-quarantine-promote-run = {
    description = "Beets quarantine approved promotion worker";
    unitConfig.RequiresMountsFor = [
      "/srv/data/beets"
      "/srv/media"
      "/srv/media/library"
      "/srv/media/quarantine/approved"
    ];
    unitConfig.ConditionPathIsDirectory = "/srv/media/quarantine/approved";
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
      WorkingDirectory = "/srv/data/beets";
      Environment = "BEETSDIR=/srv/data/beets";
      ExecStart = "${beetsQuarantineApprovedRunner}/bin/beets-quarantine-approved-runner /srv/media/quarantine/approved";
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
        "/srv/data/beets"
        "/srv/media/library"
        "/srv/media/quarantine/approved"
      ];
    };
  };

  systemd.paths.beets-inbox-watch = {
    enable = false;
    unitConfig.RequiresMountsFor = [
      "/srv/media"
      "/srv/media/inbox"
    ];
    after = [ "srv-media.mount" ];
    pathConfig.PathModified = "/srv/media/inbox";
    pathConfig.Unit = "beets-inbox-run.service";
  };

  systemd.paths.beets-quarantine-promote-watch = {
    enable = false;
    unitConfig.RequiresMountsFor = [
      "/srv/media"
      "/srv/media/quarantine/approved"
    ];
    after = [ "srv-media.mount" ];
    pathConfig.PathModified = "/srv/media/quarantine/approved";
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
}
