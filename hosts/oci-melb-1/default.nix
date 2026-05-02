{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  hasHostSecrets = builtins.pathExists ../../secrets/hosts/oci-melb-1/system.yaml;
  policyLib = import ../../lib/policy.nix { inherit lib; };
  webServicesPolicy = import ../../policy/web-services.nix;
  globals = import ../../policy/globals.nix;
  doAdminServices = policyLib.resolveHostServices webServicesPolicy "do-admin-1";
  pocketIdOidc = policyLib.mkOidcEndpoints doAdminServices."pocket-id-admin".publicUrl;
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
  applications.music.enable = true;
  applications.music.dataRoot = "/srv/data";
  applications.music.mediaRoot = "/srv/media";
  applications.music.secretFiles.host = ../../secrets/applications/music.yaml;

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
    configFile = globals.aiGateway.configFile;
    secretFiles.host = ../../secrets/services/bifrost-gateway.yaml;
  };

  services.karakeep-pod = {
    enable = true;
    oidc = {
      enable = true;
      wellknownUrl = pocketIdOidc.wellknownUrl;
      providerName = "Pocket ID";
      autoRedirect = true;
      disablePasswordAuth = true;
    };
    storage.s3.enable = true;
    secretFiles.host = ../../secrets/services/karakeep-pod.yaml;
    secretFiles.oidc = ../../secrets/hosts/oci-melb-1/oidc.yaml;
  };

  # Configurable root size — set here so it's visible in one place per host.
  disko-root-extra = "20G";

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  sops.defaultSopsFile = ../../secrets/common.yaml;

  sops.secrets = (
    lib.optionalAttrs hasHostSecrets {
      tailscale_auth_key = {
        sopsFile = ../../secrets/hosts/oci-melb-1/system.yaml;
        key = "tailscale/auth_key";
        path = "/run/secrets/tailscale.auth_key";
        mode = "0400";
      };

      cockpit_service_user_password_hash = {
        sopsFile = ../../secrets/hosts/oci-melb-1/system.yaml;
        key = "cockpit/service_user/password_hash";
        path = "/run/secrets/cockpit.service_user.password_hash";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    }
  );

  services.tailscale = lib.mkIf hasHostSecrets {
    authKeyFile = "/run/secrets/tailscale.auth_key";
  };

  services.beszel-agent-auth = {
    enable = true;
    secretFiles.host = ../../secrets/hosts/oci-melb-1/system.yaml;
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
