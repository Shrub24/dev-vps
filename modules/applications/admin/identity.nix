{
  lib,
  config,
  ...
}:
let
  cfg = config.applications.admin;
  hasTermixOidcEnv = lib.hasAttrByPath [ "sops" "templates" "termix-oidc.env" "path" ] config;
  hasQuantumOidcEnv = lib.hasAttrByPath [ "sops" "templates" "quantum-oidc.env" "path" ] config;
  termixOidcEnabled =
    config.services.admin.termix.enable && cfg.policyServices."termix-admin".access.oidc.enabled;
  quantumOidcEnabled =
    config.services.admin.quantum.enable && config.services.admin.quantum.oidc.enabled;

  pocketIdBaseUrl = cfg.policyServices."pocket-id-admin".publicUrl;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !termixOidcEnabled || hasTermixOidcEnv;
        message = "OIDC is enabled for termix-admin in policyServices, but sops template termix-oidc.env is missing.";
      }
      {
        assertion = !quantumOidcEnabled || hasQuantumOidcEnv;
        message = "Quantum OIDC is enabled, but sops template quantum-oidc.env is missing.";
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

    services.admin.quantum = lib.mkIf config.services.admin.quantum.enable {
      oidc = {
        issuerUrl = pocketIdBaseUrl;
        environmentFile =
          if quantumOidcEnabled then config.sops.templates."quantum-oidc.env".path else null;
      };
    };

  };
}
