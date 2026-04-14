{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.applications.admin;
  unstablePkgs = import inputs.nixpkgs-unstable { system = pkgs.system; };
in
{
  imports = [
    ../../modules/services/termix.nix
  ];

  options.applications.admin = {
    enable = lib.mkEnableOption "admin application composition";

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data";
      description = "Top-level data root for admin application services.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.termix.dataDir = "${cfg.dataRoot}/termix";

    services.cockpit = {
      enable = true;
      openFirewall = false;
      package = unstablePkgs.cockpit;
    };

    environment.systemPackages = [
      unstablePkgs."cockpit-podman"
      unstablePkgs."cockpit-files"
    ];

    services.udisks2.enable = true;

    services.webhook = {
      enable = true;
      ip = "127.0.0.1";
      openFirewall = false;
      hooks.health = {
        execute-command = "${pkgs.coreutils}/bin/true";
        response-message = "ok";
      };
    };

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "http://127.0.0.1:2586";
        listen-http = "127.0.0.1:2586";
      };
    };

    services.gatus = {
      enable = true;
      openFirewall = false;
      settings = {
        web.port = 8087;
        endpoints = [
          {
            name = "ntfy-health";
            url = "http://127.0.0.1:2586/v1/health";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        SIGNUPS_ALLOWED = false;
      };
    };

    services.filebrowser = {
      enable = true;
      openFirewall = false;
      settings = {
        address = "127.0.0.1";
        port = 8088;
        root = cfg.dataRoot;
      };
    };

    services.homepage-dashboard = {
      enable = true;
      openFirewall = false;
      listenPort = 8082;
      allowedHosts = "localhost:8082,127.0.0.1:8082";
    };

    services.beszel.hub = {
      enable = true;
      host = "127.0.0.1";
      port = 8090;
    };

    systemd.services.tailscale-serve-termix = {
      description = "Expose Termix via dedicated Tailscale HTTPS port";
      requires = [
        "tailscaled.service"
        "podman-termix.service"
      ];
      wants = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "podman-termix.service"
      ];
      after = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "podman-termix.service"
      ];
      partOf = [
        "tailscaled.service"
        "podman-termix.service"
      ];
      restartIfChanged = true;
      stopIfChanged = true;
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=8443 http://127.0.0.1:8083
        '';
        ExecStop = ''
          ${pkgs.tailscale}/bin/tailscale serve --https=8443 off
        '';
      };
    };

    systemd.services.tailscale-serve-cockpit = {
      description = "Expose Cockpit via dedicated Tailscale HTTPS port";
      requires = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      wants = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "cockpit.socket"
      ];
      after = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "cockpit.socket"
      ];
      partOf = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      restartIfChanged = true;
      stopIfChanged = true;
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=9443 http://127.0.0.1:${toString config.services.cockpit.port}
        '';
        ExecStop = ''
          ${pkgs.tailscale}/bin/tailscale serve --https=9443 off
        '';
      };
    };

    system.activationScripts.tailscale-serve-restart = {
      deps = [ "etc" ];
      text = ''
        ${pkgs.systemd}/bin/systemctl restart tailscale-serve-termix.service || true
        ${pkgs.systemd}/bin/systemctl restart tailscale-serve-cockpit.service || true
      '';
    };
  };
}
