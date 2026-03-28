{
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
    ../../modules/services/tailscale.nix
    ../../modules/services/syncthing.nix
    ../../modules/services/navidrome.nix
    ../../modules/services/slskd.nix
    ../../modules/providers/oci/default.nix
    ../../modules/storage/disko-root.nix
    ./users.nix
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "oci-melb-1";
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedTCPPorts = [ 22 ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  sops.defaultSopsFile = ../../secrets/common.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets = lib.mkIf (builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml) {
    tailscale_auth_key = {
      sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
      key = "tailscale/auth_key";
      path = "/run/secrets/tailscale.auth_key";
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

  services.slskd.domain = "oci-melb-1";
  services.slskd.environmentFile = "/var/lib/slskd/environment";

  systemd.tmpfiles.rules = [
    "f /var/lib/slskd/environment 0640 slskd slskd - -"
  ];

  systemd.services.tailscaled-autoconnect = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  systemd.services.navidrome = {
    wants = [
      "network-online.target"
      "syncthing.service"
    ];
    after = [
      "network-online.target"
      "syncthing.service"
    ];
  };

  systemd.services.slskd = {
    wants = [
      "network-online.target"
      "syncthing.service"
    ];
    after = [
      "network-online.target"
      "syncthing.service"
    ];
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
