{ pkgs, inputs, ... }:
let
  pkgsUnstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  beetsRuntime = import ./beets-inbox-runtime.nix {
    inherit pkgsUnstable;
  };

  beetsConfig = pkgs.writeText "beets-config.yaml" (
    builtins.readFile ../../scripts/beets-config.yaml
  );

  beetsInboxRunner = pkgs.writeShellApplication {
    name = "beets-inbox-runner";
    runtimeInputs = [
      beetsRuntime
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      BEETS_CONFIG_SOURCE=${beetsConfig}
      ${builtins.readFile ../../scripts/beets-inbox-runner.sh}
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
      "music-library"
    ];
  };

  environment.systemPackages = [
    beetsRuntime
    beetsInboxRunner
  ];

  systemd.tmpfiles.rules = [
    "d /srv/data/beets 0750 beets beets - -"
    "d /srv/data/beets/state 0750 beets beets - -"
    "d /srv/data/beets/logs 0750 beets beets - -"
    "d /srv/media/library 2775 syncthing music-library - -"
    "z /srv/media/library 2775 syncthing music-library - -"
    "a+ /srv/media/library - - - - group:music-ingest:rwx"
    "a+ /srv/media/library - - - - group:music-library:r-x"
    "a+ /srv/media/library - - - - default:group:music-ingest:rwx"
    "a+ /srv/media/library - - - - default:group:music-library:r-x"
    "d /srv/media/untagged 2755 syncthing music-library - -"
    "z /srv/media/untagged 2755 syncthing music-library - -"
    "a+ /srv/media/untagged - - - - group:music-ingest:rwx"
    "a+ /srv/media/untagged - - - - group:music-library:r-x"
    "a+ /srv/media/untagged - - - - default:group:music-ingest:rwx"
    "a+ /srv/media/untagged - - - - default:group:music-library:r-x"
  ];

  systemd.services.beets-inbox-run = {
    description = "Beets all-inbox native album import worker";
    unitConfig.RequiresMountsFor = [
      "/srv/data/beets"
      "/srv/media"
      "/srv/media/inbox"
      "/srv/media/library"
      "/srv/media/untagged"
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
        "music-library"
      ];
      WorkingDirectory = "/srv/data/beets";
      Environment = "BEETSDIR=/srv/data/beets";
      ExecStart = "${beetsInboxRunner}/bin/beets-inbox-runner /srv/media/inbox";
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
        "/srv/media/untagged"
      ];
    };
  };

  systemd.paths.beets-inbox-watch = {
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = [
      "/srv/media"
      "/srv/media/inbox"
    ];
    after = [ "srv-media.mount" ];
    pathConfig.PathModified = "/srv/media/inbox";
    pathConfig.Unit = "beets-inbox-run.service";
  };

  systemd.timers.beets-inbox-backstop = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Unit = "beets-inbox-run.service";
    };
  };
}
