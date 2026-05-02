{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.pocket-id;
  secretHelpers = import ../../../lib/secrets.nix { inherit lib; };
  policyLib = import ../../../lib/policy.nix { inherit lib; };

  oidc = policyLib.mkOidcEndpoints cfg.appUrl;
in
{
  options.services.admin.pocket-id = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Pocket ID service wiring.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/pocket-id";
      description = "Persistent data directory for Pocket ID.";
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      description = "Externally reachable Pocket ID URL used as OIDC issuer base.";
    };

    oidc = {
      issuerUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC issuer URL.";
      };

      wellknownUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC well-known URL.";
      };

      authorizationUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC authorization URL.";
      };

      tokenUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC token URL.";
      };

      userinfoUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Pocket ID OIDC userinfo URL.";
      };
    };

    secretFiles.host = secretHelpers.mkSecretFileOption "pocket-id-host-secrets";
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    assertions = [
      (secretHelpers.mkRequiredSecretAssertion {
        enable = cfg.enable;
        file = cfg.secretFiles.host;
        feature = "services.admin.pocket-id";
        label = "secretFiles.host";
      })
    ];

    sops.secrets = secretHelpers.mkSecretsFromMap cfg.secretFiles.host {
      pocket_id_encryption_key = {
        key = "pocket_id/encryption_key";
        path = "/run/secrets/pocket-id.encryption_key";
        owner = "pocket-id";
        group = "pocket-id";
      };
    };

    services.admin.pocket-id.oidc = oidc;

    services.pocket-id = {
      enable = true;
      dataDir = cfg.dataDir;
      settings = {
        APP_URL = cfg.appUrl;
        TRUST_PROXY = true;
        ENCRYPTION_KEY_FILE = "/run/secrets/pocket-id.encryption_key";
      };
    };
  };
}
