{
  lib,
  config,
  pkgs,
  ...
}:
let
  globals = import ../../policy/globals.nix;
  secretHelpers = import ../../lib/secrets.nix { inherit lib; };
  cfg = config.services.state-backups;

  enabledServices = lib.filterAttrs (_name: service: service.enable) cfg.services;
  serviceList = lib.attrValues enabledServices;

  allBackupPaths = lib.unique (
    lib.concatLists (map (service: service.paths ++ service.exportPaths) serviceList)
  );
  allExcludePaths = lib.unique (
    cfg.exclude ++ lib.concatLists (map (service: service.exclude) serviceList)
  );
  exportPathDirs = lib.unique (
    lib.concatLists (map (service: map builtins.dirOf service.exportPaths) serviceList)
  );
  managedExportPathDirs = builtins.filter (
    path: path == cfg.stagingRoot || lib.hasPrefix "${cfg.stagingRoot}/" path
  ) exportPathDirs;
  prepareCommands = lib.concatLists (map (service: service.prepareCommands) serviceList);
  cleanupCommands = lib.concatLists (map (service: service.cleanupCommands) serviceList);

  repository =
    "s3:${globals.s3.endpoint}/${cfg.bucket}"
    + lib.optionalString (cfg.repositoryPrefix != "") "/${cfg.repositoryPrefix}";

  prepareScript = ''
    set -euo pipefail
    mkdir -p ${cfg.stagingRoot}
    ${lib.concatStringsSep "\n" prepareCommands}
  '';

  cleanupScript = ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" cleanupCommands}
  '';
in
{
  options.services.state-backups = {
    enable = lib.mkEnableOption "host-scoped restic backups for mutable service state";

    backupName = lib.mkOption {
      type = lib.types.str;
      default = "state";
      description = "Restic backup job name used under services.restic.backups.";
    };

    bucket = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Dedicated object-storage bucket for this host's restic repository.";
    };

    repositoryPrefix = lib.mkOption {
      type = lib.types.str;
      default = "restic";
      description = "Optional prefix inside the host bucket used for the restic repository.";
    };

    stagingRoot = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/state-backups";
      description = "Host-local staging root for generated export artifacts captured by restic.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/srv/media" ];
      description = "Global backup exclusions for the first-wave state backup contract.";
    };

    timerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        OnCalendar = "03:30";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
      description = "Timer configuration for the canonical restic backup job.";
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      description = "Default retention policy passed to restic prune.";
    };

    checkOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--read-data-subset=1/20" ];
      description = "Repository integrity-check arguments for the canonical backup job.";
    };

    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "s3.region=${globals.s3.region}"
      ]
      ++ lib.optional globals.s3.forcePathStyle "s3.bucket-lookup=path";
      description = "Additional restic backend options derived from canonical non-secret S3 policy.";
    };

    secretFile = secretHelpers.mkSecretFileOption "state-backups-host-secrets";

    secretKeys = {
      accessKeyId = lib.mkOption {
        type = lib.types.str;
        default = "backup/s3_access_key_id";
        description = "Secret key path for the backup S3 access key ID inside the host secret file.";
      };

      secretAccessKey = lib.mkOption {
        type = lib.types.str;
        default = "backup/s3_secret_access_key";
        description = "Secret key path for the backup S3 secret access key inside the host secret file.";
      };

      resticPassword = lib.mkOption {
        type = lib.types.str;
        default = "backup/restic_password";
        description = "Secret key path for the restic repository password inside the host secret file.";
      };
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether ${name} contributes paths or hooks to the host backup job.";
              };

              mode = lib.mkOption {
                type = lib.types.enum [
                  "export"
                  "quiesce"
                  "live"
                ];
                default = "live";
                description = "Consistency mode for this service's backup contract.";
              };

              paths = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Raw mutable state paths included in the backup payload for this service.";
              };

              exportPaths = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Generated export artifact paths captured alongside raw state for this service.";
              };

              exclude = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Service-specific exclusions applied to the shared restic job.";
              };

              prepareCommands = lib.mkOption {
                type = lib.types.listOf lib.types.lines;
                default = [ ];
                description = "Shell commands run before the shared backup job for this service.";
              };

              cleanupCommands = lib.mkOption {
                type = lib.types.listOf lib.types.lines;
                default = [ ];
                description = "Shell commands run after the shared backup job for this service.";
              };
            };
          }
        )
      );
      default = { };
      description = "Per-service backup metadata consumed by the shared host backup module.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (secretHelpers.mkRequiredSecretAssertion {
        enable = cfg.enable;
        file = cfg.secretFile;
        feature = "services.state-backups";
        label = "secretFile";
      })
      {
        assertion = cfg.bucket != "";
        message = "services.state-backups.bucket must be set when host state backups are enabled.";
      }
      {
        assertion = allBackupPaths != [ ];
        message = "services.state-backups requires at least one service path or export artifact to back up.";
      }
    ];

    sops.secrets = secretHelpers.mkSecretsFromMap cfg.secretFile {
      state_backups_s3_access_key_id = {
        key = cfg.secretKeys.accessKeyId;
        path = "/run/secrets/state-backups.s3_access_key_id";
        owner = "root";
        group = "root";
      };
      state_backups_s3_secret_access_key = {
        key = cfg.secretKeys.secretAccessKey;
        path = "/run/secrets/state-backups.s3_secret_access_key";
        owner = "root";
        group = "root";
      };
      state_backups_restic_password = {
        key = cfg.secretKeys.resticPassword;
        path = "/run/secrets/state-backups.restic_password";
        owner = "root";
        group = "root";
      };
    };

    sops.templates."state-backups.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder.state_backups_s3_access_key_id}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.state_backups_s3_secret_access_key}
        AWS_DEFAULT_REGION=${globals.s3.region}
      '';
    };

    services.restic.backups.${cfg.backupName} = {
      initialize = true;
      repository = repository;
      environmentFile = config.sops.templates."state-backups.env".path;
      passwordFile = config.sops.secrets.state_backups_restic_password.path;
      paths = allBackupPaths;
      exclude = allExcludePaths;
      timerConfig = cfg.timerConfig;
      pruneOpts = cfg.pruneOpts;
      checkOpts = cfg.checkOpts;
      extraOptions = cfg.extraOptions;
    }
    // lib.optionalAttrs (prepareCommands != [ ]) { backupPrepareCommand = prepareScript; }
    // lib.optionalAttrs (cleanupCommands != [ ]) { backupCleanupCommand = cleanupScript; };

    systemd.tmpfiles.rules = [
      "d ${cfg.stagingRoot} 0750 root root - -"
    ]
    ++ map (path: "d ${path} 0750 root root - -") managedExportPathDirs;

    environment.systemPackages = with pkgs; [
      restic
      sqlite
    ];
  };
}
