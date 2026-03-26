{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/profiles/base-server.nix
    ../../modules/services/tailscale.nix
    ../../modules/providers/oci/default.nix
    ../../modules/storage/disko-root.nix
    ./users.nix
  ];

  networking.hostName = "oci-melb-1";
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  sops.defaultSopsFile = ../../secrets/common.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.tailscale_auth_key = {
    sopsFile = ../../hosts/oci-melb-1/secrets.yaml;
    key = "tailscale/auth_key";
    path = "/run/secrets/tailscale.auth_key";
    mode = "0400";
  };

  services.tailscale = {
    extraUpFlags = [
      "--hostname=oci-melb-1"
      "--advertise-tags=tag:oci-melb-1"
    ];
  } // lib.mkIf (builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml) {
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
