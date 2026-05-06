{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.bifrost-gateway;
  hostBase = "http://127.0.0.1:${toString cfg.port}";
  containerBase = "http://host.containers.internal:${toString cfg.port}";
  appDir = "${cfg.dataDir}/app";
  configPath = "${appDir}/config.json";
  parsedConfig = builtins.fromJSON (builtins.readFile cfg.configFile);
  secretHelpers = import ../../lib/secrets.nix { inherit lib; };
in
{
  options.services.bifrost-gateway = {
    enable = lib.mkEnableOption "repo-managed Bifrost AI gateway";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/maximhq/bifrost:v1.5.0-prerelease8";
      description = "Pinned Bifrost container image.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/bifrost";
      description = "Host-visible directory reserved for Bifrost app data and runtime state.";
    };

    runtimeUid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID expected by the Bifrost container for writable app-dir state.";
    };

    runtimeGid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "GID expected by the Bifrost container for writable app-dir state.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Rendered environment file containing provider secrets for Bifrost.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Listen address for the local Bifrost HTTP service.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 7411;
      description = "Listen port for the local Bifrost HTTP service.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Literal repo-owned Bifrost config.json source file rendered for file-driven mode.";
    };

    runtimePaths.appDir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = appDir;
      description = "Host-visible Bifrost app directory mounted into the container.";
    };

    runtimePaths.configPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = configPath;
      description = "Rendered canonical Bifrost config.json path on the host.";
    };

    runtimePaths.logsDir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${appDir}/logs";
      description = "Host-visible directory reserved for non-canonical Bifrost logs data.";
    };

    runtimePaths.cacheDir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${appDir}/cache";
      description = "Host-visible directory reserved for non-canonical Bifrost cache data.";
    };

    runtimePaths.vectorDir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${appDir}/vector";
      description = "Host-visible directory reserved for non-canonical Bifrost vector data.";
    };

    secretFiles.host = secretHelpers.mkSecretFileOption "bifrost-host-secrets";

    endpoint.hostBaseUrl = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${hostBase}/v1";
      description = "Loopback OpenAI-compatible endpoint for host-local consumers.";
    };

    endpoint.containerBaseUrl = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${containerBase}/v1";
      description = "OpenAI-compatible endpoint for local Podman containers on the same host.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(lib.attrByPath [ "config_store" "enabled" ] false parsedConfig);
        message = "services.bifrost-gateway.configFile must keep config_store.enabled=false in baseline file-driven mode.";
      }
      (secretHelpers.mkRequiredSecretAssertion {
        enable = cfg.enable;
        file = cfg.secretFiles.host;
        feature = "services.bifrost-gateway";
        label = "secretFiles.host";
      })
    ];

    sops.templates."bifrost.environment" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        BIFROST_ENCRYPTION_KEY=${config.sops.placeholder.bifrost_encryption_key}
        GEMINI_API_KEY=${config.sops.placeholder.bifrost_gemini_api_key}
        DEEPSEEK_API_KEY=${config.sops.placeholder.bifrost_deepseek_api_key}
      '';
    };

    sops.secrets = secretHelpers.mkSecretsFromMap cfg.secretFiles.host {
      bifrost_encryption_key = {
        key = "bifrost/encryption_key";
        path = "/run/secrets/bifrost.encryption_key";
      };
      bifrost_gemini_api_key = {
        key = "bifrost/gemini_api_key";
        path = "/run/secrets/bifrost.gemini_api_key";
      };
      bifrost_deepseek_api_key = {
        key = "bifrost/deepseek_api_key";
        path = "/run/secrets/bifrost.deepseek_api_key";
      };
    };

    virtualisation.podman.enable = true;

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root - -"
      "z ${cfg.dataDir} 0755 root root - -"
      "d ${cfg.runtimePaths.appDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "z ${cfg.runtimePaths.appDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "d ${cfg.runtimePaths.logsDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "z ${cfg.runtimePaths.logsDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "d ${cfg.runtimePaths.cacheDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "z ${cfg.runtimePaths.cacheDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "d ${cfg.runtimePaths.vectorDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
      "z ${cfg.runtimePaths.vectorDir} 0775 ${toString cfg.runtimeUid} ${toString cfg.runtimeGid} - -"
    ];

    systemd.services.bifrost-config = {
      description = "Render Bifrost config from repo-owned settings";
      wantedBy = [ "multi-user.target" ];
      before = [ "podman-bifrost.service" ];
      unitConfig.RequiresMountsFor = [ cfg.dataDir ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "bifrost-config-render" ''
          set -euo pipefail
          install -d -m 0775 -o ${toString cfg.runtimeUid} -g ${toString cfg.runtimeGid} "${cfg.runtimePaths.appDir}"
          install -d -m 0775 -o ${toString cfg.runtimeUid} -g ${toString cfg.runtimeGid} "${cfg.runtimePaths.logsDir}"
          install -d -m 0775 -o ${toString cfg.runtimeUid} -g ${toString cfg.runtimeGid} "${cfg.runtimePaths.cacheDir}"
          install -d -m 0775 -o ${toString cfg.runtimeUid} -g ${toString cfg.runtimeGid} "${cfg.runtimePaths.vectorDir}"
          install -m 0644 -o ${toString cfg.runtimeUid} -g ${toString cfg.runtimeGid} "${cfg.configFile}" "${cfg.runtimePaths.configPath}"
        '';
      };
    };

    virtualisation.oci-containers.containers.bifrost = {
      autoStart = true;
      image = cfg.image;
      ports = [
        "${cfg.listenAddress}:${toString cfg.port}:${toString cfg.port}"
      ];
      environment = {
        APP_DIR = "/app/data";
        APP_HOST = cfg.listenAddress;
        APP_PORT = toString cfg.port;
      };
      environmentFiles = lib.optionals (cfg.environmentFile != null) [ cfg.environmentFile ];
      volumes = [
        "${cfg.runtimePaths.appDir}:/app/data"
      ];
    };

    services.state-backups.services.bifrost-gateway = {
      enable = true;
      mode = "live";
      paths = [ cfg.runtimePaths.appDir ];
      exclude = [
        cfg.runtimePaths.logsDir
        cfg.runtimePaths.cacheDir
        cfg.runtimePaths.vectorDir
      ];
    };

    systemd.services."podman-bifrost" = {
      wants = [
        "network-online.target"
        "bifrost-config.service"
      ];
      after = [
        "network-online.target"
        "bifrost-config.service"
      ];
      unitConfig.RequiresMountsFor = [
        cfg.dataDir
        cfg.runtimePaths.appDir
      ];
      restartTriggers = [
        cfg.configFile
      ]
      ++ lib.optionals (cfg.environmentFile != null) [ cfg.environmentFile ];
    };
  };
}
