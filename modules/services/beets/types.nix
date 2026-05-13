{
  lib,
  ...
}:
let
  inherit (lib) mkOption;
in
{
  options = {
    runnerKind = mkOption {
      type = lib.types.enum [
        "import"
        "quarantine-interactive"
        "reconcile"
        "permission-reconcile"
        "duplicates"
      ];
      description = "Which built-in runner behavior this instance uses.";
    };

    configSource = mkOption {
      type = lib.types.path;
      description = "Path to the beets YAML config file for this runner.";
    };

    targetPath = mkOption {
      type = lib.types.str;
      description = "Target media path for this runner (e.g. inbox or quarantine root).";
    };

    description = mkOption {
      type = lib.types.str;
      default = "Beets runner";
      description = "Human-readable description of this runner instance.";
    };

    args = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments appended to the beets command for this runner.";
    };

    preCommands = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Shell commands run before the main beets command.";
    };

    postCommands = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Shell commands run after the main beets command.";
    };

    triggers = mkOption {
      type = lib.types.submodule {
        options = {
          timer = mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  OnCalendar = mkOption {
                    type = lib.types.str;
                    description = "systemd OnCalendar expression for the timer.";
                  };
                  OnBootSec = mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Optional boot delay.";
                  };
                  OnUnitActiveSec = mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Optional interval between runs.";
                  };
                  RandomizedDelaySec = mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Optional random delay to spread load.";
                  };
                };
              }
            );
            default = null;
            description = "Timer trigger configuration.";
          };
        };
      };
      default = { };
      description = "Trigger configuration for this runner.";
    };

    enableHardening = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to apply strict systemd hardening to the generated unit.";
    };

    mediaRoot = mkOption {
      type = lib.types.str;
      description = "Root directory for all media paths.";
    };

    dataDir = mkOption {
      type = lib.types.str;
      description = "Beets runtime data directory.";
    };

    writePaths = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Read-write paths required by this runner.";
    };

    readPaths = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Read-only paths required by this runner.";
    };

    mountFor = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths that must be mounted before this service runs.";
    };

    conditionDir = mkOption {
      type = lib.types.str;
      description = "Directory that must exist before this service runs.";
    };
  };
}
