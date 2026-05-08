{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.niks3-post-deploy;
  hook = config.services.niks3-auto-upload;
  hookPkg = hook.package;
in
{
  options.services.niks3-post-deploy = {
    enable = lib.mkEnableOption "post-deploy push of system closure deltas to niks3";

    excludePublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "cache.nixos.org" "nix-community.cachix.org" ];
      description = "Signing key prefixes to exclude from push. Paths signed only by these keys are skipped.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings.post-build-hook = lib.mkForce "";

    systemd.paths.niks3-post-deploy = {
      wantedBy = [ "paths.target" ];
      pathConfig = {
        PathChanged = "/run/current-system";
        Unit = "niks3-post-deploy.service";
      };
    };

    systemd.services.niks3-post-deploy = {
      description = "Queue system closure delta for niks3 upload";
      path = [ hookPkg pkgs.jq ];
      serviceConfig = {
        Type = "oneshot";
        ProtectSystem = "strict";
        PrivateTmp = true;
      };

      environment = {
        EXCLUDE_PUBLIC_KEYS = lib.concatStringsSep " " cfg.excludePublicKeys;
      };

      script = ''
        set -euo pipefail
        DIFF="$(nix store diff-closures /run/booted-system /run/current-system)"
        if [ -z "$DIFF" ]; then
          echo "Nothing changed, skipping push"
          exit 0
        fi
        # Build regex alternation from excluded key prefixes.
        EXCLUDE_RE="^($(echo "$EXCLUDE_PUBLIC_KEYS" | tr ' ' '|'))-"
        OUR_PATHS="$(echo "$DIFF" \
          | xargs nix path-info --json --sigs 2>/dev/null \
          | jq -r --arg re "$EXCLUDE_RE" '.[] | select(.sigs | any(test($re)) | not) | .path' \
          | tr '\n' ' ')"
        if [ -z "$OUR_PATHS" ]; then
          echo "No paths to push after filtering, skipping"
          exit 0
        fi
        export OUT_PATHS="$OUR_PATHS"
        exec ${lib.getExe' hookPkg "niks3-hook"} send
      '';
    };
  };
}
