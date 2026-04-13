{
  lib,
  config,
  ...
}:
let
  cfg = config.applications."edge-ingress";
in
{
  imports = [ ../../modules/services/edge-proxy-ingress.nix ];

  options.applications."edge-ingress" = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable host-level edge ingress composition.";
    };

    role = lib.mkOption {
      type = lib.types.enum [
        "none"
        "edge"
        "origin"
      ];
      default = "none";
      description = "Ingress role for this host.";
    };

    primaryDomain = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Primary ingress domain.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "ACME email for ingress certificates.";
    };

    cloudflareCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Credentials env-file for Cloudflare DNS-01 token.";
    };

    trustedProxyCidrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Optional override for trusted proxy CIDR ranges.";
    };

    authenticatedOriginPulls = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Cloudflare Authenticated Origin Pulls (mTLS).";
      };

      caCertFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "CA certificate path used for mTLS origin pull verification.";
      };
    };

    routes = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Ingress routes declared at host/application layer.";
    };
  };

  config = lib.mkIf cfg.enable {
    services."edge-proxy-ingress" = {
      inherit (cfg)
        role
        primaryDomain
        acmeEmail
        cloudflareCredentialsFile
        trustedProxyCidrs
        routes
        ;

      authenticatedOriginPulls = cfg.authenticatedOriginPulls;
    };
  };
}
