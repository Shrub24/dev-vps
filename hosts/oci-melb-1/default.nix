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

  sops.secrets.codenomad_env = {
    key = "codenomad/env";
    path = "/run/secrets/codenomad.env";
    owner = "dev";
    group = "users";
    mode = "0400";
  };

  sops.secrets.tailscale_auth_key = {
    key = "tailscale/auth_key";
    path = "/run/secrets/tailscale.auth_key";
    mode = "0400";
  };

  sops.secrets.github_token = {
    key = "github/token";
    path = "/run/secrets/github.token";
    owner = "dev";
    group = "users";
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

  systemd.services.tailscale-serve-codenomad = {
    description = "Publish CodeNomad over Tailscale Serve";
    after = [ "tailscaled-autoconnect.service" ];
    wants = [ "tailscaled-autoconnect.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/run/secrets/tailscale.auth_key";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https=443 http://127.0.0.1:9899";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve reset";
    };
  };

  system.stateVersion = "25.11";
}
