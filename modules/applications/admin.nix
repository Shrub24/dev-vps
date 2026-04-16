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
  hasGatusOidcEnv = lib.hasAttrByPath [
    "sops"
    "templates"
    "gatus-oidc.env"
    "path"
  ] config;
  hasTermixOidcEnv = lib.hasAttrByPath [
    "sops"
    "templates"
    "termix-oidc.env"
    "path"
  ] config;
in
{
  imports = [
    ../../modules/services/termix.nix
    ../../modules/services/pocket-id.nix
  ];

  options.applications.admin = {
    enable = lib.mkEnableOption "admin application composition";

    cockpit.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Cockpit and Cockpit-dependent integrations.";
    };

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data";
      description = "Top-level data root for admin application services.";
    };

    pocketIdBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://id.shrublab.xyz";
      description = "Pocket ID public base URL used by Access and app OIDC wiring.";
    };

  };

  config = lib.mkIf cfg.enable {
    services.shrublab-pocket-id = {
      enable = true;
      dataDir = "${cfg.dataRoot}/pocket-id";
      appUrl = cfg.pocketIdBaseUrl;
    };

    services.termix = {
      dataDir = "${cfg.dataRoot}/termix";
      oidc = {
        enabled = hasTermixOidcEnv;
        issuerUrl = cfg.pocketIdBaseUrl;
        environmentFile = if hasTermixOidcEnv then config.sops.templates."termix-oidc.env".path else null;
      };
    };

    services.cockpit = {
      enable = cfg.cockpit.enable;
      openFirewall = false;
      package = unstablePkgs.cockpit;
    };

    environment.systemPackages = lib.optionals cfg.cockpit.enable [
      pkgs."cockpit-podman"
      pkgs."cockpit-files"
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
      environmentFile = if hasGatusOidcEnv then config.sops.templates."gatus-oidc.env".path else null;
      settings = {
        web.port = 8087;
        security.oidc = {
          "issuer-url" = cfg.pocketIdBaseUrl;
          "redirect-url" = "https://gatus.shrublab.xyz/authorization-code/callback";
          "client-id" = "\${GATUS_OIDC_CLIENT_ID}";
          "client-secret" = "\${GATUS_OIDC_CLIENT_SECRET}";
          scopes = [ "openid" ];
        };
        endpoints = [
          {
            name = "homepage";
            url = "http://127.0.0.1:8082/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "cockpit";
            url = "http://127.0.0.1:9090/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "beszel";
            url = "http://127.0.0.1:8090/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "termix";
            url = "http://127.0.0.1:8083/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "vaultwarden";
            url = "http://127.0.0.1:8222/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "filebrowser";
            url = "http://127.0.0.1:8088/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "ntfy";
            url = "http://127.0.0.1:2586/v1/health";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "webhook";
            url = "http://127.0.0.1:9000/hooks/health";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "syncthing";
            url = "http://oci-melb-1.tail0fe19b.ts.net:8384/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "navidrome";
            url = "http://oci-melb-1.tail0fe19b.ts.net:4533/";
            interval = "1m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "slskd";
            url = "http://oci-melb-1.tail0fe19b.ts.net:5030/";
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
      enable = false;
      openFirewall = false;
      settings = {
        address = "127.0.0.1";
        port = 8088;
        root = "${cfg.dataRoot}/filebrowser";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataRoot}/filebrowser 0750 root root - -"
    ];

    services.homepage-dashboard = {
      enable = true;
      openFirewall = false;
      listenPort = 8082;
      allowedHosts = "localhost:8082,127.0.0.1:8082,admin.shrublab.xyz";
      settings = {
        title = "Shrublab Admin";
        headerStyle = "boxedWidgets";
        startUrl = "https://admin.shrublab.xyz/#overview";
        layout = {
          Glance = {
            tab = "Overview";
            style = "row";
            columns = 3;
            icon = "mdi-view-dashboard";
            useEqualHeights = true;
          };
          Access = {
            tab = "Access";
            style = "row";
            columns = 4;
            icon = "mdi-link-variant";
          };
          "0Links" = {
            style = "row";
            columns = 4;
            iconsOnly = true;
            header = false;
            icon = "mdi-bookmark-multiple";
          };
        };
      };
      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
      ];
      services = [
        {
          Glance = [
            {
              "Beszel Hub" = {
                icon = "beszel";
                description = "Fleet visibility and metrics";
                href = "https://beszel.shrublab.xyz";
                widget = {
                  type = "beszel";
                  url = "http://127.0.0.1:8090";
                };
              };
            }
            {
              Caddy = {
                icon = "caddy";
                description = "Edge proxy runtime";
                href = "https://admin.shrublab.xyz";
                widget = {
                  type = "caddy";
                  url = "http://127.0.0.1:2019";
                };
              };
            }
            {
              Tailscale = {
                icon = "tailscale";
                description = "Tailnet connectivity and node state";
                href = "https://login.tailscale.com/admin/machines";
                widget = {
                  type = "tailscale";
                  deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICEID}}";
                  key = "{{HOMEPAGE_VAR_TAILSCALE_API_KEY}}";
                };
              };
            }
            {
              Gatus = {
                icon = "gatus";
                description = "Health checks and status";
                href = "https://gatus.shrublab.xyz";
                widget = {
                  type = "gatus";
                  url = "http://127.0.0.1:8087";
                };
              };
            }
            {
              Filebrowser = {
                icon = "filebrowser";
                description = "Data root browser";
                href = "https://filebrowser.shrublab.xyz";
                widget = {
                  type = "filebrowser";
                  url = "http://127.0.0.1:8088";
                };
              };
            }
            {
              Navidrome = {
                icon = "navidrome";
                description = "Music streaming status";
                href = "https://music.shrublab.xyz";
                widget = {
                  type = "navidrome";
                  url = "http://oci-melb-1.tail0fe19b.ts.net:4533";
                  user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
                  token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                  salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                };
              };
            }
            {
              Slskd = {
                icon = "slskd";
                description = "Soulseek queue and transfer status";
                href = "https://slskd.shrublab.xyz";
                widget = {
                  type = "slskd";
                  url = "http://oci-melb-1.tail0fe19b.ts.net:5030";
                  key = "{{HOMEPAGE_VAR_SLSKD_KEY}}";
                };
              };
            }
          ];
        }
        {
          Access = [
            {
              Cockpit = {
                icon = "mdi-console-network";
                description = "Server administration";
                href = "https://cockpit.shrublab.xyz";
                siteMonitor = "http://127.0.0.1:9090";
              };
            }
            {
              Termix = {
                icon = "mdi-console";
                description = "Interactive admin shell";
                href = "https://termix.shrublab.xyz";
                siteMonitor = "http://127.0.0.1:8083";
              };
            }
            {
              Vaultwarden = {
                icon = "vaultwarden";
                description = "Password vault";
                href = "https://vaultwarden.shrublab.xyz";
                siteMonitor = "http://127.0.0.1:8222";
              };
            }
            {
              Ntfy = {
                icon = "mdi-bell-outline";
                description = "Notification broker";
                href = "https://ntfy.shrublab.xyz";
                siteMonitor = "http://127.0.0.1:2586";
              };
            }
            {
              Syncthing = {
                icon = "syncthing";
                description = "Cross-host file sync controller";
                href = "https://syncthing.shrublab.xyz";
                siteMonitor = "http://oci-melb-1.tail0fe19b.ts.net:8384";
              };
            }
          ];
        }
      ];
      bookmarks = [
        {
          "0Links" = [
            {
              "Admin Dashboard" = [
                {
                  icon = "si-homeassistant";
                  href = "https://admin.shrublab.xyz";
                  description = "";
                }
              ];
            }
            {
              Tailscale = [
                {
                  icon = "si-tailscale";
                  href = "https://login.tailscale.com/admin/machines";
                  description = "";
                }
              ];
            }
            {
              Oracle = [
                {
                  icon = "si-oracle";
                  href = "https://www.oracle.com/anz/cloud/sign-in.html";
                  description = "";
                }
              ];
            }
            {
              DigitalOcean = [
                {
                  icon = "si-digitalocean";
                  href = "https://cloud.digitalocean.com/login";
                  description = "";
                }
              ];
            }
            {
              Homelab = [
                {
                  icon = "si-github";
                  href = "https://github.com/Shrub24/nix-homelab";
                  description = "";
                }
              ];
            }
          ];
        }
      ];
    };

    services.beszel.hub = {
      enable = true;
      host = "127.0.0.1";
      port = 8090;
      environment = {
        APP_URL = "https://beszel.shrublab.xyz";
        DISABLE_PASSWORD_AUTH = "false";
        USER_CREATION = "true";
      };
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

    systemd.services.tailscale-serve-cockpit = lib.mkIf cfg.cockpit.enable {
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
        ${lib.optionalString cfg.cockpit.enable ''
          ${pkgs.systemd}/bin/systemctl restart tailscale-serve-cockpit.service || true
        ''}
      '';
    };
  };
}
