{
  lib,
  config,
  pkgs,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.kanidm;
  secretHelpers = import ../../../lib/secrets.nix { inherit lib; };
  identityPolicy = builtins.fromJSON (builtins.readFile ../../../policy/identity.json);
  oauth2Policy = identityPolicy.systems.oauth2;
  oauth2ClientPolicies = lib.filterAttrs (
    _name: clientPolicy: clientPolicy.enable or true
  ) oauth2Policy;

  oauth2Clients = lib.mapAttrs (
    _name: clientPolicy:
    {
      secretFile = cfg.secretFiles.oauth2Clients.${clientPolicy.clientId or _name};
      inherit (clientPolicy) displayName secretKeyPrefix scopeMaps;
      callbackPath = clientPolicy.callbackPath or null;
      originUrl = clientPolicy.originUrl or null;
      supplementaryScopeMaps = clientPolicy.supplementaryScopeMaps or { };
      claimMaps = clientPolicy.claimMaps or { };
    }
    // lib.optionalAttrs (clientPolicy ? routeKey) {
      route = appCfg.policyServices.${clientPolicy.routeKey};
      originLanding = appCfg.policyServices.${clientPolicy.routeKey}.publicUrl;
    }
    // lib.optionalAttrs (clientPolicy ? allowInsecureClientDisablePkce) {
      allowInsecureClientDisablePkce = clientPolicy.allowInsecureClientDisablePkce;
    }
    // lib.optionalAttrs (clientPolicy ? enableLegacyCrypto) {
      enableLegacyCrypto = clientPolicy.enableLegacyCrypto;
    }
    // lib.optionalAttrs (clientPolicy ? enableLocalhostRedirects) {
      enableLocalhostRedirects = clientPolicy.enableLocalhostRedirects;
    }
    // lib.optionalAttrs (clientPolicy ? preferShortUsername) {
      preferShortUsername = clientPolicy.preferShortUsername;
    }
    // lib.optionalAttrs (clientPolicy ? public) { public = clientPolicy.public; }
  ) oauth2ClientPolicies;

  hasIdentitySecrets = cfg.secretFiles.identity != null;
  hasProvisioningSecrets = cfg.secretFiles.provisioning != null;
  hasOauth2Clients = oauth2Clients != { };
  originHostMatch = builtins.match "https://([^/]+).*" cfg.appUrl;
  originHost = if originHostMatch == null then null else builtins.head originHostMatch;

  oauth2SecretSpecs = lib.mapAttrs' (
    name: client:
    lib.nameValuePair "kanidm_oauth2_${name}_basic_secret" {
      sopsFile = client.secretFile;
      key =
        if client ? secretKey && client.secretKey != null then
          client.secretKey
        else
          "${client.secretKeyPrefix}/client_secret";
      path = "/run/secrets/kanidm.oauth2.${name}.basic_secret";
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    }
  ) oauth2Clients;

  oauth2Provisioning = lib.mapAttrs (
    name: client:
    let
      resolvedOriginUrl =
        if client.originUrl != null then
          client.originUrl
        else
          "${client.route.publicUrl}${client.callbackPath}";
    in
    {
      displayName = client.displayName;
      originUrl = resolvedOriginUrl;
      originLanding =
        if client ? originLanding && client.originLanding != null then
          client.originLanding
        else if builtins.isList resolvedOriginUrl then
          builtins.head resolvedOriginUrl
        else
          resolvedOriginUrl;
      basicSecretFile = config.sops.secrets."kanidm_oauth2_${name}_basic_secret".path;
      public = client.public or false;
      preferShortUsername = client.preferShortUsername or false;
      allowInsecureClientDisablePkce = client.allowInsecureClientDisablePkce or false;
      enableLegacyCrypto = client.enableLegacyCrypto or false;
      enableLocalhostRedirects = client.enableLocalhostRedirects or false;
      scopeMaps = client.scopeMaps;
      supplementaryScopeMaps = client.supplementaryScopeMaps;
      claimMaps = client.claimMaps;
    }
  ) oauth2Clients;
in
{
  options.services.admin.kanidm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Kanidm service wiring.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/kanidm";
      description = "Persistent data directory for Kanidm state.";
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      description = "Externally reachable Kanidm URL used as the canonical public origin.";
    };

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Managed Kanidm domain. Defaults to the hostname derived from appUrl.";
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:8443";
      description = "Local bind address for the Kanidm server.";
    };

    tlsChainFile = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the TLS certificate chain used by the Kanidm server.";
    };

    tlsKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the TLS private key used by the Kanidm server.";
    };

    tlsReaderGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Supplementary groups granted to the Kanidm service so it can read externally managed TLS material.";
    };

    oidc = {
      clientPathPrefix = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Base client-specific Kanidm OIDC path prefix.";
      };

      tokenUrl = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Canonical Kanidm OAuth2 token endpoint.";
      };

      clients = lib.mkOption {
        type = lib.types.attrs;
        readOnly = true;
        description = "Canonical client-specific Kanidm OIDC endpoint outputs keyed by oauth2 client identifier.";
      };
    };

    secretFiles.identity = secretHelpers.mkSecretFileOption "kanidm-identity-secrets";
    secretFiles.provisioning = secretHelpers.mkSecretFileOption "kanidm-provisioning-overlay";
    secretFiles.oauth2Clients = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Per-client OIDC secret source files keyed by Kanidm oauth2 client id.";
    };

    backup = {
      exportDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/kanidm/backups";
        description = "Directory containing Kanidm automatic backup artifacts for restic capture.";
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "15 03 * * *";
        description = "Cron schedule for Kanidm automatic backups, aligned to run before the shared restic job.";
      };

      versions = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of Kanidm automatic backup artifacts retained locally.";
      };
    };
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    assertions = [
      {
        assertion = originHost != null;
        message = "services.admin.kanidm.appUrl must be a valid https URL.";
      }
      {
        assertion = config.services.identity.oidc.providerUrl == cfg.appUrl;
        message = "services.admin.kanidm.appUrl must stay aligned with services.identity.oidc.providerUrl.";
      }
    ]
    ++ lib.mapAttrsToList (name: _client: {
      assertion = builtins.hasAttr name cfg.secretFiles.oauth2Clients;
      message = "services.admin.kanidm.secretFiles.oauth2Clients.${name} must be set when system.oauth2.${name}.enable=true.";
    }) oauth2Clients
    ++ lib.mapAttrsToList (name: client: {
      assertion = client.originUrl != null || ((client.route != null) && (client.callbackPath != null));
      message = "system.oauth2.${name} must define originUrl directly or provide both routeKey and callbackPath.";
    }) oauth2Clients;

    sops.secrets =
      (lib.optionalAttrs hasIdentitySecrets (
        secretHelpers.mkSecretsFromMap cfg.secretFiles.identity {
          kanidm_admin_password = {
            key = "kanidm/admin_password";
            path = "/run/secrets/kanidm.admin_password";
            owner = "kanidm";
            group = "kanidm";
          };
          kanidm_idm_admin_password = {
            key = "kanidm/idm_admin_password";
            path = "/run/secrets/kanidm.idm_admin_password";
            owner = "kanidm";
            group = "kanidm";
          };
        }
      ))
      // (lib.optionalAttrs hasProvisioningSecrets {
        kanidm_provisioning_overlay = {
          sopsFile = cfg.secretFiles.provisioning;
          format = "json";
          key = "";
          path = "/run/secrets/kanidm.provisioning.json";
          owner = "kanidm";
          group = "kanidm";
          mode = "0400";
        };
      })
      // oauth2SecretSpecs;

    services.admin.kanidm.oidc = {
      clientPathPrefix = config.services.identity.oidc.clientPathPrefix;
      tokenUrl = config.services.identity.oidc.tokenUrl;
      clients = config.services.identity.oidc.clients;
    };

    services.kanidm = {
      package = pkgs.kanidmWithSecretProvisioning_1_9;

      client = {
        enable = true;
        settings.uri = cfg.appUrl;
      };

      server = {
        enable = true;
        settings = {
          origin = cfg.appUrl;
          domain = if cfg.domain != null then cfg.domain else originHost;
          bindaddress = cfg.bindAddress;
          tls_chain = cfg.tlsChainFile;
          tls_key = cfg.tlsKeyFile;
          role = "WriteReplica";
          online_backup = {
            path = cfg.backup.exportDir;
            schedule = cfg.backup.schedule;
            versions = cfg.backup.versions;
          };
        };
      };

      provision = lib.mkIf (hasIdentitySecrets || hasOauth2Clients || hasProvisioningSecrets) (
        {
          enable = true;
          instanceUrl = cfg.appUrl;
          systems.oauth2 = oauth2Provisioning;
        }
        // lib.optionalAttrs hasIdentitySecrets {
          adminPasswordFile = config.sops.secrets.kanidm_admin_password.path;
          idmAdminPasswordFile = config.sops.secrets.kanidm_idm_admin_password.path;
        }
        // lib.optionalAttrs hasProvisioningSecrets {
          extraJsonFile = config.sops.secrets.kanidm_provisioning_overlay.path;
        }
      );
    };

    environment.systemPackages = [ pkgs.kanidm_1_9 ];

    services.state-backups.services.kanidm = {
      enable = true;
      mode = "export";
      paths = [ cfg.dataDir ];
      exportPaths = [ cfg.backup.exportDir ];
    };

    systemd.services.kanidm.serviceConfig.SupplementaryGroups = cfg.tlsReaderGroups;
    systemd.services.kanidm.after = [ "caddy.service" ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 kanidm kanidm - -"
      "z ${cfg.dataDir} 0750 kanidm kanidm - -"
      "d ${cfg.backup.exportDir} 0750 kanidm kanidm - -"
      "z ${cfg.backup.exportDir} 0750 kanidm kanidm - -"
    ];
  };
}
