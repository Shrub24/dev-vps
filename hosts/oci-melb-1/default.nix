{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/profiles/base-server.nix
    ../../modules/profiles/worker-interface.nix
    ../../modules/applications/admin.nix
    ../../modules/applications/music.nix
    ../../modules/providers/oci/default.nix
    ../../modules/storage/disko-root.nix
    ../../modules/core/users.nix
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "oci-melb-1";
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  sops.defaultSopsFile = ../../secrets/common.yaml;

  sops.templates."beets-config.yaml" =
    lib.mkIf (builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml)
      {
        owner = "beets";
        group = "beets";
        mode = "0440";
        content =
          builtins.replaceStrings
            [ "REPLACE_WITH_DISCOGS_USER_TOKEN" ]
            [ config.sops.placeholder.beets_discogs_token ]
            (builtins.readFile ../../scripts/beets-config.yaml);
      };

  sops.secrets = lib.mkIf (builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml) {
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
  };

  services.tailscale = {
    extraUpFlags = [
      "--hostname=oci-melb-1"
      "--advertise-tags=tag:oci-melb-1"
    ];
  }
  // lib.mkIf (builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml) {
    authKeyFile = "/run/secrets/tailscale.auth_key";
  };

  systemd.services.tailscaled-autoconnect = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
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
