{
  lib,
}: {
  /*
    Light helper library for common secret-contract patterns.

    Design:
      - Not a DSL — just reusable Nix functions that keep boilerplate low
        without hiding what's happening.
      - All helpers return plain Nix attrsets/options/assertions so callers
        always retain control.
      - Callers still own the actual sops.secrets/sops.templates wiring;
        helpers just make declaring the contract surface easier.
  */

  # -------------------------------------------------------
  # Option declarations (the "contract surface")
  # -------------------------------------------------------

  /*
    Create a standard secret-file path option.

    Example:
      secretFiles.host = libHelpers.mkSecretFileOption "music-host-secrets";
      secretFiles.providers = libHelpers.mkSecretFileOption "music-provider-secrets";
  */
  mkSecretFileOption =
    name:
    lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to SOPS-encrypted file for ${name} secrets.";
    };

  /*
    Create a standard secret key (SOPS YAML key) option.

    Example:
      secretKeys.tailscaleAuth = libHelpers.mkSecretKeyOption "tailscale/auth_key";
  */
  mkSecretKeyOption =
    defaultKey:
    lib.mkOption {
      type = lib.types.str;
      default = defaultKey;
      description = "SOPS YAML key path for this secret.";
    };

  # -------------------------------------------------------
  # Assertions (enforce contract)
  # -------------------------------------------------------

  /*
    Assert that a required secret file is provided when the feature is enabled.

    Example:
      assertions = [
        (libHelpers.mkRequiredSecretAssertion {
          enable = cfg.enable;
          file = cfg.secretFiles.host;
          feature = "applications.music";
          label = "secretFiles.host";
        })
      ];
  */
  mkRequiredSecretAssertion =
    {
      enable,
      file,
      feature,
      label,
    }:
    {
      assertion = !enable || file != null;
      message = "${feature}.enable is true but ${feature}.${label} is not set.";
    };

  # -------------------------------------------------------
  # Secret registration (common shapes)
  # -------------------------------------------------------

  /*
    Create a single sops.secrets entry with standard defaults.

    Example:
      sops.secrets = {
        my_token = libHelpers.mkSimpleSecret {
          sopsFile = cfg.secretFiles.host;
          key = "myapp/token";
          path = "/run/secrets/myapp.token";
          owner = "myapp";
        };
      };
  */
  mkSimpleSecret =
    {
      sopsFile,
      key,
      path,
      owner ? "root",
      group ? "root",
      mode ? "0400",
    }:
    {
      inherit sopsFile key path owner group mode;
    };

  /*
    Create a set of sops.secrets entries from a mapping.

    Example:
      sops.secrets = libHelpers.mkSecretsFromMap cfg.secretFiles.host {
        tailscale_auth_key = { key = "tailscale/auth_key"; path = "/run/secrets/tailscale.auth_key"; };
        beets_discogs_token = { key = "beets/discogs_token"; path = "/run/secrets/beets.discogs_token"; owner = "beets"; group = "beets"; };
      };
  */
  mkSecretsFromMap =
    sopsFile: map:
    builtins.mapAttrs (_name: spec:
      {
        inherit sopsFile;
        inherit (spec) key path;
        owner = spec.owner or "root";
        group = spec.group or "root";
        mode = spec.mode or "0400";
      }
    ) map;
}
