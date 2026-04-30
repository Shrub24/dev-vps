{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.applications.admin;
  hasTermixOidcEnv = lib.hasAttrByPath [ "sops" "templates" "termix-oidc.env" "path" ] config;
  hasQuantumOidcEnv = lib.hasAttrByPath [ "sops" "templates" "quantum-oidc.env" "path" ] config;
  termixEnabled = config.services.admin.termix.enable;
  termixRoute = cfg.policyServices."termix-admin";
  termixOidcEnabled = termixEnabled && termixRoute.access.oidc.enabled;
  quantumOidcEnabled = config.services.admin.quantum.enable && config.services.admin.quantum.oidc.enabled;
  pocketIdOidc = config.services.admin.pocket-id.oidc;
in
{
  imports = [
    ../../services/admin/termix.nix
    ../../services/admin/pocket-id.nix
    ../../services/admin/cockpit.nix
    ../../services/admin/webhook.nix
    ../../services/admin/ntfy.nix
    ../../services/admin/gatus.nix
    ../../services/admin/vaultwarden.nix
    ../../services/admin/quantum.nix
    ../../services/admin/homepage/default.nix
    ../../services/admin/beszel.nix
  ];

  options.applications.admin = {
    enable = lib.mkEnableOption "admin application composition";

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data";
      description = "Top-level data root for admin application services.";
    };

    policyServices = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Resolved host services from policy/web-services.nix for SSOT endpoint consumption.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
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

      services.admin.termix.enable = lib.mkDefault true;
      services.admin."pocket-id".enable = lib.mkDefault true;
      services.admin.cockpit.enable = lib.mkDefault true;
      services.admin.webhook.enable = lib.mkDefault true;
      services.admin.ntfy.enable = lib.mkDefault true;
      services.admin.gatus.enable = lib.mkDefault true;
      services.admin.vaultwarden.enable = lib.mkDefault true;
      services.admin.quantum.enable = lib.mkDefault false;
      services.admin.homepage.enable = lib.mkDefault true;
      services.admin.beszel.enable = lib.mkDefault true;
    }

    (lib.mkIf config.services.admin.pocket-id.enable {
      services.admin."pocket-id" = {
        dataDir = "${cfg.dataRoot}/pocket-id";
        appUrl = cfg.policyServices."pocket-id-admin".publicUrl;
      };
    })

    (lib.mkIf termixEnabled {
      services.admin.termix = {
        dataDir = "${cfg.dataRoot}/termix";
        oidc = {
          enabled = termixOidcEnabled;
          issuerUrl = pocketIdOidc.issuerUrl;
          environmentFile = if termixOidcEnabled then config.sops.templates."termix-oidc.env".path else null;
        };
      };

      systemd.services.tailscale-serve-termix = {
        description = "Expose Termix via dedicated Tailscale HTTPS port";
        requires = [
          "tailscaled.service"
          "podman-termix.service"
        ];
        wants = [
          "tailscaled-autoconnect.service"
          "tailscaled.service"
          "podman-termix.service"
        ];
        after = [
          "tailscaled-autoconnect.service"
          "tailscaled.service"
          "podman-termix.service"
        ];
        partOf = [
          "tailscaled.service"
          "podman-termix.service"
        ];
        restartIfChanged = true;
        stopIfChanged = true;
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=8443 ${termixRoute.upstream}
          '';
          ExecStop = ''
            ${pkgs.tailscale}/bin/tailscale serve --https=8443 off
          '';
        };
      };
    })

    (lib.mkIf config.services.admin.quantum.enable {
      services.admin.quantum.oidc = {
        issuerUrl = pocketIdOidc.issuerUrl;
        environmentFile = if quantumOidcEnabled then config.sops.templates."quantum-oidc.env".path else null;
      };
    })
  ]);
}
