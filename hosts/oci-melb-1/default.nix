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
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "oci-melb-1";
  services.resolved.enable = true;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  disko.devices.disk.main.device = "/dev/sda";
  disko.devices.disk.media.device = "/dev/sdb";
  applications.music.dataRoot = "/srv/data";
  applications.music.mediaRoot = "/srv/media";

  systemd.tmpfiles.rules = [
    "d ${config.applications.music.dataRoot} 0755 root root - -"
    "z ${config.applications.music.dataRoot} 0755 root root - -"
    "d ${config.applications.music.mediaRoot} 0755 root root - -"
    "z ${config.applications.music.mediaRoot} 0755 root root - -"
  ];

  applications."edge-ingress" = {
    enable = true;
    role = "origin";
  };

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
      SLSKD_PASSWORD=${config.sops.placeholder.soulsync_slskd_api_key}
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
    (lib.mkIf hasHostSecrets {
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
    })
    // (lib.mkIf hasProviderSecrets {
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
