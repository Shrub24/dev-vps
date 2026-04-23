{
  lib,
  config,
  ...
}:
let
  cfg = config.applications.admin;
  hasTermixOidcEnv = lib.hasAttrByPath [ "sops" "templates" "termix-oidc.env" "path" ] config;
  termixOidcEnabled =
    config.services.admin.termix.enable && cfg.policyServices."termix-admin".access.oidc.enabled;

  pocketIdBaseUrl = cfg.policyServices."pocket-id-admin".publicUrl;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !termixOidcEnabled || hasTermixOidcEnv;
        message = "OIDC is enabled for termix-admin in policyServices, but sops template termix-oidc.env is missing.";
      }
    ];

    services.shrublab-pocket-id = lib.mkIf config.services.admin.pocket-id.enable {
      dataDir = "${cfg.dataRoot}/pocket-id";
      appUrl = pocketIdBaseUrl;
    };

    services.termix = lib.mkIf config.services.admin.termix.enable {
      dataDir = "${cfg.dataRoot}/termix";
      oidc = {
        enabled = termixOidcEnabled;
        issuerUrl = pocketIdBaseUrl;
        environmentFile = if termixOidcEnabled then config.sops.templates."termix-oidc.env".path else null;
      };
    };

  };
}
