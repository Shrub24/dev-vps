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

  beetsPermissionReconcile = pkgs.writeShellApplication {
    name = "beets-permission-reconcile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.acl
    ];
    text = ''
      set -euo pipefail

      TAGGED_ROOT=/srv/media/library/tagged
      UNTAGGED_ROOT=/srv/media/library/untagged

      if [[ -d "$TAGGED_ROOT" ]]; then
        find "$TAGGED_ROOT" -type d -exec chgrp media {} +
        find "$TAGGED_ROOT" -type d -exec chmod 2775 {} +
        find "$TAGGED_ROOT" -type f -exec chgrp media {} +
        find "$TAGGED_ROOT" -type f -exec chmod 0664 {} +
      fi

      if [[ -d "$UNTAGGED_ROOT" ]]; then
        find "$UNTAGGED_ROOT" -type d -exec chgrp remediation {} +
        find "$UNTAGGED_ROOT" -type d -exec chmod 2775 {} +
        find "$UNTAGGED_ROOT" -type f -exec chgrp remediation {} +
        find "$UNTAGGED_ROOT" -type f -exec chmod 0664 {} +
        setfacl -R -m g:media:rX "$UNTAGGED_ROOT"
        find "$UNTAGGED_ROOT" -type d -exec setfacl -m d:g:media:r-x {} +
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
      "remediation"
    ];
  };

  environment.systemPackages = [
    beetsRuntime
    beetsInboxRunner
    beetsPermissionReconcile
  ];

  systemd.tmpfiles.rules = [
    "d /srv/data/beets 0750 beets beets - -"
    "d /srv/data/beets/state 0750 beets beets - -"
    "d /srv/data/beets/logs 0750 beets beets - -"
    "d /srv/data/beets/importfeeds 0750 beets beets - -"
    "a+ /srv/data/beets/logs - - - - user:dev:r-x"
    "a+ /srv/data/beets/logs - - - - default:user:dev:r-x"
    "d /srv/media/library 2775 root media - -"
    "d /srv/media/library/tagged 2775 root media - -"
    "d /srv/media/library/untagged 2775 root remediation - -"
    "a+ /srv/media/library/untagged - - - - group:media:r-x"
    "a+ /srv/media/library/untagged - - - - default:group:media:r-x"
  ];

  systemd.services.beets-inbox-run = {
    description = "Beets all-inbox native album import worker";
    unitConfig.RequiresMountsFor = [
      "/srv/data/beets"
      "/srv/media"
      "/srv/media/inbox"
      "/srv/media/library"
      "/srv/media/library/untagged"
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
        "/srv/media/library/untagged"
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

  systemd.timers.beets-inbox-backstop = {
    enable = false;
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Unit = "beets-inbox-run.service";
    };
  };
}
