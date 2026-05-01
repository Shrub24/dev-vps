{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  hasHostSecrets = builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml;
  hasProviderSecrets = builtins.pathExists ../../hosts/oci-melb-1/secrets.providers.yaml;
  policyLib = import ../../lib/policy.nix { inherit lib; };
  webServicesPolicy = import ../../policy/web-services.nix;
  globals = import ../../policy/globals.nix;
  doAdminServices = policyLib.resolveHostServices webServicesPolicy "do-admin-1";
  pocketIdWellknownUrl = "${
    doAdminServices."pocket-id-admin".publicUrl
  }/.well-known/openid-configuration";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/profiles/base-server.nix
    ../../modules/profiles/worker-interface.nix
    ../../modules/applications/music.nix
    ../../modules/applications/edge-ingress.nix
    ../../modules/providers/oci/default.nix
    ../../modules/storage/disko-root.nix
    ../../modules/core/users.nix
    ../../modules/services/admin/cockpit.nix
    ../../modules/services/bifrost-gateway.nix
    ../../modules/services/karakeep.nix
    ./cockpit-auth.nix
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "oci-melb-1";
  services.resolved.enable = true;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  networking.firewall.interfaces.podman0.allowedTCPPorts = [
    5030
    4533
  ];

  disko.devices.disk.main.device = "/dev/sda";
  disko.devices.disk.media.device = "/dev/sdb";
  applications.music.dataRoot = "/srv/data";
  applications.music.mediaRoot = "/srv/media";

  boot.loader.grub.configurationLimit = 10;

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=300M
    SystemKeepFree=1G
    MaxRetentionSec=7day
  '';

  systemd.tmpfiles.rules = [
    "d ${config.applications.music.dataRoot} 0755 root root - -"
    "z ${config.applications.music.dataRoot} 0755 root root - -"
    "d ${config.applications.music.mediaRoot} 0755 root root - -"
    "z ${config.applications.music.mediaRoot} 0755 root root - -"
    "a+ ${config.applications.music.dataRoot} - - - - user:dev:r-X"
    "a+ ${config.applications.music.dataRoot} - - - - default:user:dev:r-X"
  ];

  systemd.services.music-dev-data-access-reconcile = {
    description = "Reconcile dev read/traverse access on music data root";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "music-dev-data-access-reconcile" ''
        set -euo pipefail
        if [ -d "${config.applications.music.dataRoot}" ]; then
          ${pkgs.acl}/bin/setfacl -m u:dev:rX "${config.applications.music.dataRoot}"
          find "${config.applications.music.dataRoot}" -xdev -type d -exec ${pkgs.acl}/bin/setfacl -m d:u:dev:rX {} +
        fi
      '';
    };
  };

  systemd.services.podman-storage-prune = {
    description = "Prune unused Podman storage artifacts";
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      set -euo pipefail
      podman system prune --all --force --volumes
    '';
  };

  systemd.timers.podman-storage-prune = {
    description = "Periodic Podman storage prune";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  applications."edge-ingress" = {
    enable = true;
    role = "origin";
  };

  services.bifrost-gateway = {
    enable = true;
    dataDir = "/srv/data/bifrost";
    environmentFile = config.sops.templates."bifrost.environment".path;
    settings = {
      version = 2;
      encryption_key = "env.BIFROST_ENCRYPTION_KEY";
      providers.openai.keys = [
        {
          name = "openai-primary";
          value = "env.OPENAI_API_KEY";
          weight = 1;
          models = [ "*" ];
          aliases = {
            "${globals.aiGateway.aliases.text}" = globals.aiGateway.upstreamModels.text;
            "${globals.aiGateway.aliases.image}" = globals.aiGateway.upstreamModels.image;
            "${globals.aiGateway.aliases.embedding}" = globals.aiGateway.upstreamModels.embedding;
            "${globals.aiGateway.aliases.fallback}" = globals.aiGateway.upstreamModels.fallback;
          };
        }
      ];
    };
  };

  services.karakeep-oci.enable = true;
  services.karakeep-oci.environmentFile = config.sops.templates."karakeep.environment".path;
  services.karakeep-oci.oidc = {
    enable = true;
    wellknownUrl = pocketIdWellknownUrl;
    providerName = "Pocket ID";
    autoRedirect = true;
    disablePasswordAuth = true;
  };
  services.karakeep-oci.storage.s3.enable = true;

  # Configurable root size — set here so it's visible in one place per host.
  disko-root-extra = "20G";

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  sops.defaultSopsFile = ../../secrets/common.yaml;

  sops.templates."beets-config.yaml" = lib.mkIf hasHostSecrets {
    owner = "beets";
    group = "beets";
    mode = "0440";
    content =
      builtins.replaceStrings
        [ "REPLACE_WITH_DISCOGS_USER_TOKEN" ]
        [ config.sops.placeholder.beets_discogs_token ]
        (builtins.readFile ../../scripts/beets-config.yaml);
  };

  sops.templates."beets-approved-config.yaml" = lib.mkIf hasHostSecrets {
    owner = "beets";
    group = "beets";
    mode = "0440";
    content =
      builtins.replaceStrings
        [ "REPLACE_WITH_DISCOGS_USER_TOKEN" ]
        [ config.sops.placeholder.beets_discogs_token ]
        (builtins.readFile ../../scripts/beets-approved-config.yaml);
  };

  sops.templates."soulsync.env" = lib.mkIf hasHostSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      SLSKD_API_KEY=${config.sops.placeholder.soulsync_slskd_api_key}
      SOULSYNC_DISCOGS_TOKEN=${config.sops.placeholder.soulsync_discogs_token}
      SOULSYNC_NAVIDROME_USERNAME=${config.sops.placeholder.soulsync_navidrome_username}
      SOULSYNC_NAVIDROME_PASSWORD=${config.sops.placeholder.soulsync_navidrome_password}
    '';
  };

  sops.templates."soulsync-config.json" = lib.mkIf hasHostSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      {
        "active_media_server": "navidrome",
        "metadata": {
          "fallback_source": "discogs"
        },
        "discogs": {
          "token": "${config.sops.placeholder.soulsync_discogs_token}"
        },
        "soulseek": {
          "slskd_url": "http://host.containers.internal:5030",
          "api_key": "${config.sops.placeholder.soulsync_slskd_api_key}",
          "download_path": "${config.applications.music.mediaRoot}/inbox/slskd",
          "transfer_path": "${config.applications.music.mediaRoot}/library"
        },
        "import": {
          "staging_path": "${config.applications.music.mediaRoot}/quarantine/approved",
          "replace_lower_quality": false
        },
        "navidrome": {
          "base_url": "http://host.containers.internal:4533",
          "username": "${config.sops.placeholder.soulsync_navidrome_username}",
          "password": "${config.sops.placeholder.soulsync_navidrome_password}",
          "auto_detect": true
        }
      }
    '';
  };

  sops.templates."slskd.env" = lib.mkIf hasHostSecrets {
    owner = "slskd";
    group = "slskd";
    mode = "0400";
    content = ''
      SLSKD_SLSK_USERNAME=${config.sops.placeholder.slskd_slsk_username}
      SLSKD_SLSK_PASSWORD=${config.sops.placeholder.slskd_slsk_password}
      SLSKD_API_KEY=${config.sops.placeholder.soulsync_slskd_api_key}
      SLSKD_NO_AUTH=false
      SLSKD_USERNAME=api-only
      SLSKD_PASSWORD=${config.sops.placeholder.slskd_web_password}
    '';
  };

  sops.templates."tagr.env" = lib.mkIf hasHostSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      AUTH_SECRET=${config.sops.placeholder.tagr_auth_secret}
      AUTH_USER=${config.sops.placeholder.tagr_auth_user}
      AUTH_PASSWORD=${config.sops.placeholder.tagr_auth_password}
    '';
  };

  sops.templates."karakeep.environment" = lib.mkIf hasHostSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      NEXTAUTH_SECRET=${config.sops.placeholder.karakeep_nextauth_secret}
      MEILI_MASTER_KEY=${config.sops.placeholder.karakeep_meilisearch_master_key}
      OAUTH_CLIENT_ID=${config.sops.placeholder.karakeep_oidc_client_id}
      OAUTH_CLIENT_SECRET=${config.sops.placeholder.karakeep_oidc_client_secret}
      OPENAI_BASE_URL=${config.services.bifrost-gateway.endpoint.containerBaseUrl}
      OPENAI_API_KEY=bifrost-local
      INFERENCE_TEXT_MODEL=${globals.aiGateway.aliases.text}
      INFERENCE_IMAGE_MODEL=${globals.aiGateway.aliases.image}
      EMBEDDING_TEXT_MODEL=${globals.aiGateway.aliases.embedding}
      ASSET_STORE_S3_ENDPOINT=${globals.s3.endpoint}
      ASSET_STORE_S3_REGION=${globals.s3.region}
      ASSET_STORE_S3_BUCKET=${globals.s3.bucket}
      ASSET_STORE_S3_ACCESS_KEY_ID=${config.sops.placeholder.karakeep_asset_store_s3_access_key_id}
      ASSET_STORE_S3_SECRET_ACCESS_KEY=${config.sops.placeholder.karakeep_asset_store_s3_secret_access_key}
    '';
  };

  sops.templates."bifrost.environment" = lib.mkIf hasHostSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      BIFROST_ENCRYPTION_KEY=${config.sops.placeholder.bifrost_encryption_key}
      OPENAI_API_KEY=${config.sops.placeholder.bifrost_openai_api_key}
    '';
  };

  sops.templates."soulsync-spotify.env" = lib.mkIf hasProviderSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      SOULSYNC_SPOTIFY_CLIENT_ID=${config.sops.placeholder.soulsync_spotify_client_id}
      SOULSYNC_SPOTIFY_CLIENT_SECRET=${config.sops.placeholder.soulsync_spotify_client_secret}
    '';
  };

  sops.templates."soulsync-deezer.env" = lib.mkIf hasProviderSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      SOULSYNC_DEEZER_ARL=${config.sops.placeholder.soulsync_deezer_arl}
    '';
  };

  sops.templates."soulsync-youtube.env" = lib.mkIf hasProviderSecrets {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      SOULSYNC_YOUTUBE_COOKIES=${config.sops.placeholder.soulsync_youtube_cookies}
    '';
  };

  sops.secrets =
    (lib.optionalAttrs hasHostSecrets {
      tailscale_auth_key = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "tailscale/auth_key";
        path = "/run/secrets/tailscale.auth_key";
        mode = "0400";
      };

      beets_discogs_token = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "beets/discogs_token";
        path = "/run/secrets/beets.discogs_token";
        owner = "beets";
        group = "beets";
        mode = "0400";
      };

      soulsync_slskd_api_key = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "soulsync/slskd_api_key";
        path = "/run/secrets/soulsync.slskd_api_key";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      soulsync_discogs_token = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "soulsync/discogs_token";
        path = "/run/secrets/soulsync.discogs_token";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      soulsync_navidrome_username = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "soulsync/navidrome_username";
        path = "/run/secrets/soulsync.navidrome_username";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      soulsync_navidrome_password = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "soulsync/navidrome_password";
        path = "/run/secrets/soulsync.navidrome_password";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      slskd_slsk_username = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "slskd/slsk_username";
        path = "/run/secrets/slskd.slsk_username";
        owner = "slskd";
        group = "slskd";
        mode = "0400";
      };

      slskd_slsk_password = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "slskd/slsk_password";
        path = "/run/secrets/slskd.slsk_password";
        owner = "slskd";
        group = "slskd";
        mode = "0400";
      };

      slskd_web_password = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "slskd/web_password";
        path = "/run/secrets/slskd.web_password";
        owner = "slskd";
        group = "slskd";
        mode = "0400";
      };

      cockpit_service_user_password_hash = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "cockpit/service_user/password_hash";
        path = "/run/secrets/cockpit.service_user.password_hash";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      tagr_auth_secret = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "tagr/auth_secret";
        path = "/run/secrets/tagr.auth_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      tagr_auth_user = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "tagr/auth_user";
        path = "/run/secrets/tagr.auth_user";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      tagr_auth_password = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "tagr/auth_password";
        path = "/run/secrets/tagr.auth_password";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      karakeep_nextauth_secret = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "karakeep/nextauth_secret";
        path = "/run/secrets/karakeep.nextauth_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      karakeep_meilisearch_master_key = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "karakeep/meilisearch_master_key";
        path = "/run/secrets/karakeep.meilisearch_master_key";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      karakeep_oidc_client_id = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "karakeep/oidc_client_id";
        path = "/run/secrets/karakeep.oidc_client_id";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      karakeep_oidc_client_secret = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "karakeep/oidc_client_secret";
        path = "/run/secrets/karakeep.oidc_client_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      karakeep_asset_store_s3_access_key_id = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "karakeep/asset_store_s3_access_key_id";
        path = "/run/secrets/karakeep.asset_store_s3_access_key_id";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      karakeep_asset_store_s3_secret_access_key = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "karakeep/asset_store_s3_secret_access_key";
        path = "/run/secrets/karakeep.asset_store_s3_secret_access_key";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      bifrost_encryption_key = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "bifrost/encryption_key";
        path = "/run/secrets/bifrost.encryption_key";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      bifrost_openai_api_key = {
        sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
        key = "bifrost/openai_api_key";
        path = "/run/secrets/bifrost.openai_api_key";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    })
    // (lib.optionalAttrs hasProviderSecrets {
      soulsync_spotify_client_id = {
        sopsFile = ../../hosts/oci-melb-1/secrets.providers.yaml;
        key = "soulsync/spotify_client_id";
        path = "/run/secrets/soulsync.spotify_client_id";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      soulsync_spotify_client_secret = {
        sopsFile = ../../hosts/oci-melb-1/secrets.providers.yaml;
        key = "soulsync/spotify_client_secret";
        path = "/run/secrets/soulsync.spotify_client_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      soulsync_deezer_arl = {
        sopsFile = ../../hosts/oci-melb-1/secrets.providers.yaml;
        key = "soulsync/deezer_arl";
        path = "/run/secrets/soulsync.deezer_arl";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      soulsync_youtube_cookies = {
        sopsFile = ../../hosts/oci-melb-1/secrets.providers.yaml;
        key = "soulsync/youtube_cookies";
        path = "/run/secrets/soulsync.youtube_cookies";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    });

  services.tailscale = lib.mkIf hasHostSecrets {
    authKeyFile = "/run/secrets/tailscale.auth_key";
  };

  services.beszel-agent-auth = {
    enable = true;
    tokenSopsFile = ../../hosts/oci-melb-1/secrets.yaml;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      libuuid
      xz
      icu
    ];
  };

  system.stateVersion = "25.11";
}
