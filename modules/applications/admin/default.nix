{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.applications.admin;
  globals = import ../../../policy/globals.nix;
  secretHelpers = import ../../../lib/secrets.nix { inherit lib; };

  termixEnabled = config.services.admin.termix.enable;
  termixRoute = cfg.policyServices."termix-admin";
  termixOidcEnabled = termixEnabled && termixRoute.access.oidc.enabled;
  quantumOidcEnabled =
    config.services.admin.quantum.enable && config.services.admin.quantum.oidc.enabled;
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
      default = globals.applications.admin.dataRoot;
      description = "Top-level data root for admin application services.";
    };

    policyServices = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Resolved host services from policy/web-services.nix for SSOT endpoint consumption.";
    };

    secretFiles.host = secretHelpers.mkSecretFileOption "admin-host-secrets";
    secretFiles.oidc = secretHelpers.mkSecretFileOption "admin-oidc-secrets";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Base config with assertions and default service enables
      {
        assertions = [
          (secretHelpers.mkRequiredSecretAssertion {
            enable = cfg.enable;
            file = cfg.secretFiles.host;
            feature = "applications.admin";
            label = "secretFiles.host";
          })
          (secretHelpers.mkRequiredSecretAssertion {
            enable = termixOidcEnabled;
            file = cfg.secretFiles.oidc;
            feature = "applications.admin";
            label = "secretFiles.oidc";
          })
          (secretHelpers.mkRequiredSecretAssertion {
            enable = quantumOidcEnabled;
            file = cfg.secretFiles.oidc;
            feature = "applications.admin";
            label = "secretFiles.oidc";
          })
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

      # Pass-through: propagate secretFiles to sub-services
      {
        services.admin.vaultwarden.secretFiles.host = cfg.secretFiles.host;
        services.admin.homepage.secretFiles.host = cfg.secretFiles.host;
        services.admin.quantum.secretFiles.host = cfg.secretFiles.host;
        services.admin.quantum.secretFiles.oidc = cfg.secretFiles.oidc;
        services.admin.termix.secretFiles.oidc = cfg.secretFiles.oidc;
        services.admin.pocket-id.secretFiles.host = cfg.secretFiles.host;
      }

      # All host-level secrets - from host-scoped secret file
      {
        sops.secrets = secretHelpers.mkSecretsFromMap cfg.secretFiles.host {
          admin_ssh_identity = {
            key = "admin/ssh/identity";
            path = "/run/secrets/admin.ssh.identity";
            owner = "root";
            group = "root";
          };
          admin_ssh_known_hosts = {
            key = "admin/ssh/known_hosts";
            path = "/run/secrets/admin.ssh.known_hosts";
            owner = "root";
            group = "root";
          };
        };
      }

      # Admin data root tmpfiles and ACL
      {
        systemd.tmpfiles.rules = [
          "d ${cfg.dataRoot} 0755 root root - -"
          "z ${cfg.dataRoot} 0755 root root - -"
          "a+ ${cfg.dataRoot} - - - - user:dev:r-X"
          "a+ ${cfg.dataRoot} - - - - default:user:dev:r-X"
        ];

        systemd.services.admin-dev-data-access-reconcile = {
          description = "Reconcile dev read/traverse access on admin data root";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-tmpfiles-setup.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "admin-dev-data-access-reconcile" ''
              set -euo pipefail
              if [ -d "${cfg.dataRoot}" ]; then
                ${pkgs.acl}/bin/setfacl -m u:dev:rX "${cfg.dataRoot}"
                find "${cfg.dataRoot}" -xdev -type d ! -path "${cfg.dataRoot}/quantum/mnt" ! -path "${cfg.dataRoot}/quantum/mnt/*" -exec ${pkgs.acl}/bin/setfacl -m d:u:dev:rX {} +
              fi
            '';
          };
        };
      }

      # Pocket-ID service configuration
      (lib.mkIf config.services.admin.pocket-id.enable {
        services.admin.pocket-id = {
          dataDir = "${cfg.dataRoot}/pocket-id";
          appUrl = cfg.policyServices."pocket-id-admin".publicUrl;
        };
      })

      # Termix OIDC and Tailscale serve
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

      # Quantum OIDC configuration
      (lib.mkIf config.services.admin.quantum.enable {
        services.admin.quantum.oidc = {
          issuerUrl = pocketIdOidc.issuerUrl;
          environmentFile =
            if quantumOidcEnabled then config.sops.templates."quantum-oidc.env".path else null;
        };
      })
    ]
  );
}
