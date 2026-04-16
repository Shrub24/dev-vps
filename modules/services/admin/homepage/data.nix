{
  policyServices,
  ...
}:
let
  requireRoute = name: policyServices.${name};
  host = name: (requireRoute name).publicHost;

  serviceHref = name: "https://${host name}";
in
{
  settings = {
    title = "Shrublab Admin";
    headerStyle = "boxedWidgets";
    startUrl = "${serviceHref "admin-homepage"}#overview";
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
            href = serviceHref "beszel-admin";
            widget = {
              type = "beszel";
              url = (requireRoute "beszel-admin").upstream;
            };
          };
        }
        {
          Caddy = {
            icon = "caddy";
            description = "Edge proxy runtime";
            href = serviceHref "admin-homepage";
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
            href = serviceHref "gatus-admin";
            widget = {
              type = "gatus";
              url = (requireRoute "gatus-admin").upstream;
            };
          };
        }
        {
          Filebrowser = {
            icon = "filebrowser";
            description = "Data root browser";
            href = serviceHref "filebrowser-admin";
            widget = {
              type = "filebrowser";
              url = (requireRoute "filebrowser-admin").upstream;
            };
          };
        }
        {
          Navidrome = {
            icon = "navidrome";
            description = "Music streaming status";
            href = serviceHref "navidrome";
            widget = {
              type = "navidrome";
              url = (requireRoute "navidrome").upstream;
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
            href = serviceHref "slskd-admin";
            widget = {
              type = "slskd";
              url = (requireRoute "slskd-admin").upstream;
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
            href = serviceHref "cockpit-admin";
            siteMonitor = (requireRoute "cockpit-admin").healthUrl;
          };
        }
        {
          Termix = {
            icon = "mdi-console";
            description = "Interactive admin shell";
            href = serviceHref "termix-admin";
            siteMonitor = (requireRoute "termix-admin").healthUrl;
          };
        }
        {
          Vaultwarden = {
            icon = "vaultwarden";
            description = "Password vault";
            href = serviceHref "vaultwarden-admin";
            siteMonitor = (requireRoute "vaultwarden-admin").healthUrl;
          };
        }
        {
          Ntfy = {
            icon = "mdi-bell-outline";
            description = "Notification broker";
            href = serviceHref "ntfy-admin";
            siteMonitor = (requireRoute "ntfy-admin").healthUrl;
          };
        }
        {
          Syncthing = {
            icon = "syncthing";
            description = "Cross-host file sync controller";
            href = serviceHref "syncthing-admin";
            siteMonitor = (requireRoute "syncthing-admin").healthUrl;
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
              href = serviceHref "admin-homepage";
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
}
