{
  defaults = {
    exposureMode = "direct";
    category = "app";
    path = "/";
    declarePublic = true;
    stripPrefix = false;

    access = {
      requireCloudflareAccess = true;
      oidc = {
        enabled = false;
        provider = "cloudflare-access";
      };
      policies = [ "allow_admins" ];
    };

    cloudflare = {
      proxied = true;
      authenticatedOriginPulls = true;
    };

    health = {
      path = "/health";
      expectedStatus = 200;
    };
  };

  hosts = {
    do-admin-1 = {
      defaults = { };

      services = {
        navidrome = {
          subdomain = "music";
          origin = {
            scheme = "http";
            host = "oci-melb-1.tail0fe19b.ts.net";
            port = 4533;
          };
          exposureMode = "tailscale-upstream";
          category = "app";
          access.requireCloudflareAccess = false;
          cloudflare = {
            proxied = true;
            authenticatedOriginPulls = true;
          };
          health.path = "/ping";
        };

        termix-admin = {
          subdomain = "termix";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 8083;
          };
          category = "admin";
          access.oidc.enabled = true;
        };

        pocket-id-admin = {
          subdomain = "id";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 1411;
          };
          category = "admin";
          access.requireCloudflareAccess = false;
          cloudflare = {
            proxied = true;
            authenticatedOriginPulls = true;
          };
        };

        admin-homepage = {
          subdomain = "admin";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 8082;
          };
          category = "admin";
        };

        cockpit-admin = {
          subdomain = "cockpit";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 9090;
          };
          category = "admin";
        };

        beszel-admin = {
          subdomain = "beszel";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 8090;
          };
          category = "admin";
          access.oidc.enabled = true;
        };

        gatus-admin = {
          subdomain = "gatus";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 8087;
          };
          category = "admin";
          access.oidc.enabled = true;
        };

        vaultwarden-admin = {
          subdomain = "vaultwarden";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 8222;
          };
          category = "admin";
          access.requireCloudflareAccess = false;
        };

        filebrowser-admin = {
          subdomain = "filebrowser";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 8088;
          };
          category = "admin";
        };

        ntfy-admin = {
          subdomain = "ntfy";
          origin = {
            scheme = "http";
            host = "127.0.0.1";
            port = 2586;
          };
          category = "admin";
        };

        syncthing-admin = {
          subdomain = "syncthing";
          origin = {
            scheme = "http";
            host = "oci-melb-1.tail0fe19b.ts.net";
            port = 8384;
          };
          exposureMode = "tailscale-upstream";
          category = "admin";
        };
      };
    };
  };
}
