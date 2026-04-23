{
  lib,
  config,
  ...
}:
let
  cfg = config.services.beszel-agent-auth;
in
{
  options.services.beszel-agent-auth = {
    enable = lib.mkEnableOption "Beszel agent auth wiring";

    tokenSopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Host-scoped SOPS file containing Beszel agent token.";
    };

    secretKeyPrefix = lib.mkOption {
      type = lib.types.str;
      default = "beszel/agent";
      description = "SOPS key prefix for Beszel agent credentials.";
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tokenSopsFile != null;
        message = "services.beszel-agent-auth.enable is true but services.beszel-agent-auth.tokenSopsFile is not set.";
      }
    ];

    sops.templates."beszel-agent.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        KEY=${config.sops.placeholder.beszel_agent_key}
        TOKEN=${config.sops.placeholder.beszel_agent_token}
      '';
    };

    sops.secrets = {
      beszel_agent_key = {
        sopsFile = ../../secrets/common.yaml;
        key = "${cfg.secretKeyPrefix}/key";
        path = "/run/secrets/beszel.agent.key";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      beszel_agent_token = {
        sopsFile = cfg.tokenSopsFile;
        key = "${cfg.secretKeyPrefix}/token";
        path = "/run/secrets/beszel.agent.token";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    services.beszel.agent = {
      enable = true;
      environmentFile = config.sops.templates."beszel-agent.env".path;
    };
  };
}
