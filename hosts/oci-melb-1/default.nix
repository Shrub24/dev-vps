{ pkgs, ... }:
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

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.tailscale_auth_key = {
    key = "tailscale/auth_key";
    path = "/run/secrets/tailscale.auth_key";
    mode = "0400";
  };

  services.tailscale = {
    authKeyFile = "/run/secrets/tailscale.auth_key";
    extraUpFlags = [
      "--hostname=oci-melb-1"
      "--advertise-tags=tag:oci-melb-1"
    ];
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
