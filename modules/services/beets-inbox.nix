{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.beets-inbox;
  secretHelpers = import ../../lib/secrets.nix { inherit lib; };

  mediaPaths = rec {
    inboxDir = if cfg.inboxDir != null then cfg.inboxDir else "${cfg.mediaRoot}/inbox";
    libraryDir = if cfg.libraryDir != null then cfg.libraryDir else "${cfg.mediaRoot}/library";
    quarantineDir =
      if cfg.quarantineDir != null then cfg.quarantineDir else "${cfg.mediaRoot}/quarantine";
    untaggedDir = "${quarantineDir}/untagged";
    approvedDir = "${quarantineDir}/approved";
    writableMediaDirs = [ libraryDir quarantineDir untaggedDir approvedDir ];
  };

  beetsRuntime = pkgs.python3Packages.beets.override {
    pluginOverrides = {
      bandcamp = {
        enable = true;
        propagatedBuildInputs = [ pkgs.python3Packages.beetcamp ];
      };
    };
  };

  beetsConfigNames = [
    "beets-config.yaml"
    "beets-approved-config.yaml"
    "beets-quarantine-config.yaml"
  ];

  mkBeetsConfig = name:
    pkgs.writeText name (builtins.readFile ../../scripts/${name});

  mkBeetsConfigSource = name:
    if lib.hasAttrByPath [ "sops" "templates" name "path" ] config then
      config.sops.templates.${name}.path
    else
      mkBeetsConfig name;

  beetsSecretEntries = [
    {
      secretName = "beets_discogs_token";
      key = "beets/discogs_token";
      placeholder = "REPLACE_WITH_DISCOGS_USER_TOKEN";
    }
    {
      secretName = "beets_spotify_client_id";
      key = "beets/spotify_client_id";
      placeholder = "REPLACE_WITH_SPOTIFY_CLIENT_ID";
    }
    {
      secretName = "beets_spotify_client_secret";
      key = "beets/spotify_client_secret";
      placeholder = "REPLACE_WITH_SPOTIFY_CLIENT_SECRET";
    }
  ];

  mkSopsTemplate = name: {
    owner = "beets";
    group = "beets";
    mode = "0440";
    content =
      builtins.replaceStrings
        (map (e: e.placeholder) beetsSecretEntries)
        (map (e: config.sops.placeholder.${e.secretName}) beetsSecretEntries)
        (builtins.readFile ../../scripts/${name});
  };

  mkSopsSecret = { secretName, key, ... }: {
    sopsFile = cfg.secretFiles.host;
    inherit key;
    path = "/run/secrets/beets.${builtins.replaceStrings [ "beets_" ] [ "" ] secretName}";
    owner = "beets";
    group = "beets";
  };

  beetsRunners = rec {
    inbox = pkgs.writeShellApplication {
      name = "beets-inbox-runner";
      runtimeInputs = [ beetsRuntime pkgs.coreutils pkgs.findutils pkgs.gnused ];
      text = ''
        BEETS_CONFIG_SOURCE=${mkBeetsConfigSource "beets-config.yaml"}
        BEETS_APPROVED_CONFIG_SOURCE=${mkBeetsConfigSource "beets-approved-config.yaml"}
        ${builtins.readFile ../../scripts/beets-inbox-runner.sh}
      '';
    };

    quarantineApproved = pkgs.writeShellApplication {
      name = "beets-quarantine-approved-runner";
      runtimeInputs = [ beetsRuntime pkgs.coreutils pkgs.findutils pkgs.gnused ];
      text = ''
        BEETS_CONFIG_SOURCE=${mkBeetsConfigSource "beets-config.yaml"}
        ${builtins.readFile ../../scripts/beets-inbox-runner.sh}
      '';
    };

    quarantine = pkgs.writeShellApplication {
      name = "beets-quarantine-runner";
      runtimeInputs = [ beetsRuntime pkgs.coreutils ];
      text = ''
        set -euo pipefail
        BEETS_DATA_DIR="${cfg.dataDir}"
        export BEETSDIR="$BEETS_DATA_DIR"
        export HOME="$BEETS_DATA_DIR"
        mkdir -p "$BEETS_DATA_DIR/state"
        TARGET="''${1:-${mediaPaths.untaggedDir}}"
        exec beet -c "${mkBeetsConfigSource "beets-quarantine-config.yaml"}" import "$TARGET"
      '';
    };

    interactive = pkgs.writeShellApplication {
      name = "beets-interactive";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        set -euo pipefail
        TARGET="''${1:-${mediaPaths.untaggedDir}}"
        exec sudo -u beets -H "${quarantine}/bin/beets-quarantine-runner" "$TARGET"
      '';
    };

    convert = pkgs.writeShellApplication {
      name = "beets-convert-runner";
      runtimeInputs = [ beetsRuntime pkgs.coreutils pkgs.ffmpeg ];
      text = ''
        set -euo pipefail
        BEETS_DATA_DIR="${cfg.dataDir}"
        export BEETSDIR="$BEETS_DATA_DIR"
        export HOME="$BEETS_DATA_DIR"
        mkdir -p "$BEETS_DATA_DIR/state"
        QUERY="''${1:-}"
        exec beet -c "${mkBeetsConfigSource "beets-config.yaml"}" convert ''${QUERY:+"$QUERY"}
      '';
    };

    reconcile = pkgs.writeShellApplication {
      name = "beets-reconcile-runner";
      runtimeInputs = [ beetsRuntime pkgs.coreutils pkgs.ffmpeg ];
      text = ''
        set -euo pipefail
        BEETS_DATA_DIR="${cfg.dataDir}"
        export BEETSDIR="$BEETS_DATA_DIR"
        export HOME="$BEETS_DATA_DIR"
        mkdir -p "$BEETS_DATA_DIR/state"
        CONFIG="${mkBeetsConfigSource "beets-config.yaml"}"
        echo "=== beet update (re-read tags from files) ==="
        beet -c "$CONFIG" update -a
        echo "=== beet check (verify library integrity) ==="
        beet -c "$CONFIG" check
        echo "=== beet convert (lossless -> AIFF where not yet converted) ==="
        beet -c "$CONFIG" convert
        echo "=== beet duplicates (detect duplicate albums) ==="
        beet -c "$CONFIG" duplicates -a
        echo "=== beet move (reorganize files to match path templates) ==="
        beet -c "$CONFIG" move
      '';
    };

    permissionReconcile = pkgs.writeShellApplication {
      name = "beets-permission-reconcile";
      runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.acl ];
      text = ''
        set -euo pipefail
        fixup() {
          local dir="$1"
          [[ -d "$dir" ]] || return 0
          find "$dir" -type d -exec chgrp music-ingest {} +
          find "$dir" -type d -exec chmod 2775 {} +
          find "$dir" -type f -exec chgrp music-ingest {} +
          find "$dir" -type f -exec chmod 0664 {} +
          setfacl -R -m g:music-ingest:rwx "$dir"
          find "$dir" -type d -exec setfacl -m d:g:music-ingest:rwX {} +
          setfacl -R -m g:media:r-X "$dir"
          find "$dir" -type d -exec setfacl -m d:g:media:r-X {} +
        }
        fixup "${mediaPaths.libraryDir}"
        fixup "${mediaPaths.quarantineDir}"
        fixup "${mediaPaths.untaggedDir}"
        fixup "${mediaPaths.approvedDir}"
      '';
    };
  };

  beetsServiceDefaults = {
    Type = "oneshot";
    User = "beets";
    Group = "beets";
    SupplementaryGroups = [ "music-ingest" "media" ];
    WorkingDirectory = cfg.dataDir;
    Environment = "BEETSDIR=${cfg.dataDir}";
    ExecStartPost = [ "+${beetsRunners.permissionReconcile}/bin/beets-permission-reconcile" ];
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
  };

  mkBeetsService = { name, description, conditionDir, execStart, mountFor, writePaths }:
    assert builtins.isString name && name != "";
    assert builtins.isString description;
    assert builtins.isString conditionDir;
    assert builtins.isString execStart;
    assert builtins.isList mountFor;
    assert builtins.isList writePaths;
    {
      inherit description;
      unitConfig = {
        RequiresMountsFor = mountFor;
        ConditionPathIsDirectory = conditionDir;
      };
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = beetsServiceDefaults // {
        ExecStart = execStart;
        ReadWritePaths = writePaths ++ [ "/run/secrets/rendered" ];
      };
    };

  aclForDir = dir: [
    "a+ ${dir} - - - - group:music-ingest:rwx"
    "a+ ${dir} - - - - default:group:music-ingest:rwX"
    "a+ ${dir} - - - - group:media:r-X"
    "a+ ${dir} - - - - default:group:media:r-X"
  ];

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

  options.services.beets-inbox.secretFiles.host =
    secretHelpers.mkSecretFileOption "beets-host-secrets";

  config = lib.mkIf (cfg.secretFiles.host != null) {
    assertions = [
      (secretHelpers.mkRequiredSecretAssertion {
        enable = cfg.secretFiles.host != null;
        file = cfg.secretFiles.host;
        feature = "services.beets-inbox";
        label = "secretFiles.host";
      })
    ];

    sops.templates = builtins.listToAttrs (map (name: {
      inherit name;
      value = mkSopsTemplate name;
    }) beetsConfigNames);

    sops.secrets = builtins.listToAttrs (map (e: {
      name = e.secretName;
      value = mkSopsSecret e;
    }) beetsSecretEntries);

    users.groups.beets = { };
    users.users.beets = {
      isSystemUser = true;
      group = "beets";
      home = cfg.dataDir;
      createHome = false;
      extraGroups = [ "music-ingest" "media" ];
    };

    environment.systemPackages = [
      beetsRuntime
      beetsRunners.inbox
      beetsRunners.quarantineApproved
      beetsRunners.quarantine
      beetsRunners.interactive
      beetsRunners.permissionReconcile
      beetsRunners.convert
      beetsRunners.reconcile
    ];

    systemd.tmpfiles.rules =
      [
        "d ${cfg.dataDir} 0750 beets beets - -"
        "d ${cfg.dataDir}/state 0750 beets beets - -"
        "d ${cfg.dataDir}/logs 0750 beets beets - -"
        "a+ ${cfg.dataDir}/logs - - - - user:dev:r-x"
        "a+ ${cfg.dataDir}/logs - - - - default:user:dev:r-x"
        "d ${mediaPaths.untaggedDir} 2775 root music-ingest - -"
        "d ${mediaPaths.approvedDir} 2775 root music-ingest - -"
      ]
      ++ aclForDir mediaPaths.untaggedDir
      ++ aclForDir mediaPaths.approvedDir;

    systemd.services.beets-inbox-run = mkBeetsService {
      name = "beets-inbox-run";
      description = "Beets all-inbox native album import worker";
      conditionDir = mediaPaths.inboxDir;
      execStart = "${beetsRunners.inbox}/bin/beets-inbox-runner ${mediaPaths.inboxDir}";
      mountFor = [ cfg.dataDir cfg.mediaRoot mediaPaths.inboxDir mediaPaths.libraryDir mediaPaths.untaggedDir mediaPaths.approvedDir ];
      writePaths = [ cfg.dataDir mediaPaths.inboxDir mediaPaths.libraryDir mediaPaths.untaggedDir mediaPaths.approvedDir ];
    };

    systemd.services.beets-quarantine-promote-run = mkBeetsService {
      name = "beets-quarantine-promote-run";
      description = "Beets quarantine approved promotion worker";
      conditionDir = mediaPaths.approvedDir;
      execStart = "${beetsRunners.quarantineApproved}/bin/beets-quarantine-approved-runner ${mediaPaths.approvedDir}";
      mountFor = [ cfg.dataDir cfg.mediaRoot mediaPaths.libraryDir mediaPaths.approvedDir ];
      writePaths = [ cfg.dataDir mediaPaths.libraryDir mediaPaths.approvedDir ];
    };

    systemd.paths.beets-inbox-watch = {
      enable = false;
      unitConfig.RequiresMountsFor = [ cfg.mediaRoot mediaPaths.inboxDir ];
      pathConfig.PathModified = mediaPaths.inboxDir;
      pathConfig.Unit = "beets-inbox-run.service";
    };

    systemd.paths.beets-quarantine-promote-watch = {
      enable = false;
      unitConfig.RequiresMountsFor = [ cfg.mediaRoot mediaPaths.approvedDir ];
      pathConfig.PathModified = mediaPaths.approvedDir;
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
