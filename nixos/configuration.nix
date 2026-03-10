{
  modulesPath,
  lib,
  pkgs,
  ...
}: let
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCcCrrwmxabl1/fnYTkrlMLa+I4ucauph3GMtTvDg4B/EyzsEFUB+sOEf9sLpdnocsxOaUu4e6qE2sZRWJHafIo8gidE3JB/Ogf9aeddWjukeYH3EddJDd0iPqCL2JMPdVpNi/Ly/RAcxi2ENSZf5eoX30EEkC3s2kzxJ1znlhS6YOjG1XFdmjtf5bMnj4JFxXNhEa5mpzR6G5Qua2lcaA53+J20mldyRGYSrQAnR2E0x0k0XS95/jJ7xo7pCqPyCkT2zBTzRoEb1A+4ulHsuW9d6nk6W61nUX3QDj4gNGcq9jUmtHVd+OdZPKU1ILWWHm8x2YDPron3wihe072VWEhwG8ojmfqeKUceF41/ymN1ws9DhxNaF+ofJwuGR8J9afPXeYfV1qxOvpSwKHvLCNsPP88HApd+0q5JADeclUGtrnfNxNolnTowA6dFJ1tqXE7doYiyaoitnHmR8DO/k0SQ21wnScfJUSdkD/Ifcz8M+36qB2/SkdUG788hpIObs0= saurabhj@Saurabh-fedora"
  ];
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko-config.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  networking.hostName = "dev-vps";
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    openFirewall = true;
    hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
      {
        type = "ecdsa";
        bits = 256;
        path = "/etc/ssh/ssh_host_ecdsa_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/etc/ssh/ssh_host_rsa_key";
      }
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.mutableUsers = false;
  users.users.dev = {
    isNormalUser = true;
    description = "Dev User";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = sshKeys;
  };
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    codenomad
    repo-sync
  ];

  programs.zsh.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.direnv.enableZshIntegration = true;

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

  sops.defaultSopsFile = ../secrets/secrets.yaml;
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
    enable = true;
    authKeyFile = "/run/secrets/tailscale.auth_key";
    extraUpFlags = [
      "--hostname=dev-vps"
      "--advertise-tags=tag:dev-vps"
    ];
  };

  systemd.services.tailscaled-autoconnect = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  systemd.services.codenomad = {
    description = "CodeNomad Server";
    after = [ "network-online.target" "tailscaled-autoconnect.service" ];
    wants = [ "network-online.target" "tailscaled-autoconnect.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/run/secrets/codenomad.env";
    environment = {
      CLI_UI_NO_UPDATE = "true";
      CLI_UI_AUTO_UPDATE = "false";
    };
    serviceConfig = {
      Type = "simple";
      User = "dev";
      Group = "users";
      WorkingDirectory = "/home/dev";
      EnvironmentFile = "/run/secrets/codenomad.env";
      ExecStart = "${pkgs.codenomad}/bin/codenomad --host 127.0.0.1 --https false --http true --http-port 9899 --workspace-root /home/dev/workspaces --ui-no-update --ui-auto-update false";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.tailscale-serve-codenomad = {
    description = "Publish CodeNomad over Tailscale Serve";
    after = [ "tailscaled-autoconnect.service" "codenomad.service" ];
    wants = [ "tailscaled-autoconnect.service" "codenomad.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/run/secrets/tailscale.auth_key";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https=443 http://127.0.0.1:9899";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve reset";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/dev/workspaces 0755 dev users - -"
    "d /home/dev/workspaces/github 0755 dev users - -"
    "d /home/dev/state 0755 dev users - -"
  ];

  system.stateVersion = "24.11";
}
