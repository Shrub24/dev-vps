{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services."edge-proxy-ingress";

  routeNames = builtins.attrNames cfg.routes;
  routeByName = name: cfg.routes.${name};
  isPublicRoute = route: route.exposureMode != "tailscale-only";
  publicRouteNames = builtins.filter (name: isPublicRoute (routeByName name)) routeNames;
  publicRoutes = map routeByName publicRouteNames;

  hostForRoute =
    route:
    if route.subdomain != null then "${route.subdomain}.${cfg.primaryDomain}" else cfg.primaryDomain;

  siteHosts = lib.unique (map hostForRoute publicRoutes);

  needsAccessHeader = route: route.cloudflareAccessRequired;

  sanitize = value: lib.replaceStrings [ "." "-" "/" "@" ] [ "_" "_" "_" "_" ] value;

  mkRouteHandle =
    name: route:
    let
      id = sanitize name;
      accessGuard =
        if needsAccessHeader route then
          ''
            @${id}_missing_access not header Cf-Access-Authenticated-User-Email *
            respond @${id}_missing_access "Cloudflare Access required" 403
          ''
        else
          "";
    in
    if route.path == "/" then
      ''
        # ${name} (${route.exposureMode})
        handle {
          ${accessGuard}
          reverse_proxy ${route.upstream}
        }
      ''
    else if route.stripPrefix then
      ''
        # ${name} (${route.exposureMode})
        handle_path ${route.path}* {
          ${accessGuard}
          reverse_proxy ${route.upstream}
        }
      ''
    else
      ''
        # ${name} (${route.exposureMode})
        @${id}_path path ${route.path}*
        handle @${id}_path {
          ${accessGuard}
          reverse_proxy ${route.upstream}
        }
      '';

  hostRouteNames =
    host: builtins.filter (name: hostForRoute (routeByName name) == host) publicRouteNames;

  hostAopValues =
    host: map (name: (routeByName name).authenticatedOriginPullsRequired) (hostRouteNames host);

  hostRequiresAop = host: builtins.any (value: value) (hostAopValues host);

  hostHasMixedAopRequirement =
    host:
    let
      values = lib.unique (hostAopValues host);
    in
    builtins.length values > 1;

  mTlsBlock =
    host:
    if cfg.authenticatedOriginPulls.enable && hostRequiresAop host then
      ''
        client_auth {
          mode require_and_verify
          trust_pool file {
            pem_file ${cfg.authenticatedOriginPulls.caCertFile}
          }
        }
      ''
    else
      "";

  trustedProxyLines = lib.concatStringsSep "\n          " cfg.trustedProxyCidrs;

  caddyGlobal =
    if cfg.role == "edge" then
      ''
        {
          servers {
            trusted_proxies static ${trustedProxyLines}
            client_ip_headers CF-Connecting-IP X-Forwarded-For
          }
        }
      ''
    else
      "";

  renderSite =
    host:
    let
      namesForHost = builtins.filter (name: hostForRoute (routeByName name) == host) publicRouteNames;
      sortedNames = lib.sort (
        a: b: builtins.stringLength (routeByName a).path > builtins.stringLength (routeByName b).path
      ) namesForHost;
      routeBlocks = lib.concatStringsSep "\n" (
        map (name: mkRouteHandle name (routeByName name)) sortedNames
      );
    in
    ''
      ${host} {
        tls /var/lib/acme/${cfg.primaryDomain}/fullchain.pem /var/lib/acme/${cfg.primaryDomain}/key.pem {
          ${mTlsBlock host}
        }
        encode zstd
      ${routeBlocks}
      }
    '';

  caddyfile = pkgs.writeText "Caddyfile-edge-proxy" ''
    ${caddyGlobal}

    ${lib.concatStringsSep "\n\n" (map renderSite siteHosts)}
  '';

  certExtraDomains = [ "*.${cfg.primaryDomain}" ];

  routeAssertions =
    lib.map (
      name:
      let
        route = routeByName name;
      in
      {
        assertion = lib.hasPrefix "/" route.path;
        message = "edge-proxy-ingress route '${name}' path must start with '/'.";
      }
    ) routeNames
    ++ lib.map (
      name:
      let
        route = routeByName name;
      in
      {
        assertion = route.exposureMode == "tailscale-only" || route.declarePublic;
        message = "edge-proxy-ingress route '${name}' must set declarePublic=true for public exposure modes.";
      }
    ) routeNames;
in
{
  options.services."edge-proxy-ingress" = {
    role = lib.mkOption {
      type = lib.types.enum [
        "none"
        "edge"
        "origin"
      ];
      default = "none";
      description = "Host ingress role: none, edge (publishes routes), or origin (private upstream only).";
    };

    primaryDomain = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Primary domain used for all ingress subdomain/path routing.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Email used for ACME registration when role=edge.";
    };

    cloudflareCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to env-file containing CLOUDFLARE_DNS_API_TOKEN for ACME DNS-01.";
    };

    trustedProxyCidrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
        "2400:cb00::/32"
        "2606:4700::/32"
        "2803:f800::/32"
        "2405:b500::/32"
        "2405:8100::/32"
        "2a06:98c0::/29"
        "2c0f:f248::/32"
      ];
      description = "Trusted proxy CIDRs for preserving original client IP headers (Cloudflare ranges by default).";
    };

    authenticatedOriginPulls = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require Cloudflare Authenticated Origin Pulls (mTLS) for edge routes.";
      };

      caCertFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to CA cert file used to verify Cloudflare origin-pull client certs.";
      };
    };

    routes = lib.mkOption {
      default = { };
      description = "Route map keyed by route name.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subdomain = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional subdomain label under primaryDomain.";
            };

            path = lib.mkOption {
              type = lib.types.str;
              default = "/";
              description = "Path prefix for route matching.";
            };

            upstream = lib.mkOption {
              type = lib.types.str;
              description = "Reverse-proxy upstream target (e.g. http://127.0.0.1:4533).";
            };

            exposureMode = lib.mkOption {
              type = lib.types.enum [
                "direct"
                "tailscale-upstream"
                "tailscale-only"
              ];
              default = "tailscale-upstream";
              description = "Exposure mode for this route.";
            };

            declarePublic = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Explicit opt-in required for public route rendering.";
            };

            category = lib.mkOption {
              type = lib.types.enum [
                "app"
                "admin"
                "sensitive"
              ];
              default = "app";
              description = "Route category used by policy guardrails.";
            };

            cloudflareAccessRequired = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Require Cloudflare Access identity header before proxying.";
            };

            stripPrefix = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use handle_path to strip path prefix before proxying.";
            };

            authenticatedOriginPullsRequired = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this route requires Cloudflare Authenticated Origin Pulls (mTLS) at host TLS layer.";
            };
          };
        }
      );
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.role != "edge" || cfg.primaryDomain != "";
        message = "edge-proxy-ingress requires primaryDomain when role=edge.";
      }
      {
        assertion = cfg.role != "edge" || cfg.acmeEmail != "";
        message = "edge-proxy-ingress requires acmeEmail when role=edge.";
      }
      {
        assertion = cfg.role != "edge" || cfg.cloudflareCredentialsFile != null;
        message = "edge-proxy-ingress requires cloudflareCredentialsFile when role=edge.";
      }
      {
        assertion = !cfg.authenticatedOriginPulls.enable || cfg.authenticatedOriginPulls.caCertFile != null;
        message = "edge-proxy-ingress requires authenticatedOriginPulls.caCertFile when authenticatedOriginPulls.enable=true.";
      }
      {
        assertion = cfg.authenticatedOriginPulls.enable || !(builtins.any hostRequiresAop siteHosts);
        message = "edge-proxy-ingress has public hosts requiring authenticated origin pulls, but authenticatedOriginPulls.enable=false.";
      }
      {
        assertion = !(builtins.any hostHasMixedAopRequirement siteHosts);
        message = "edge-proxy-ingress cannot mix authenticatedOriginPullsRequired true/false routes on the same host.";
      }
      {
        assertion = cfg.role == "edge" || cfg.routes == { };
        message = "edge-proxy-ingress routes may only be declared when role=edge.";
      }
    ]
    ++ routeAssertions;

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.role == "edge" && publicRouteNames != [ ]) (
      lib.mkAfter [
        80
        443
      ]
    );

    security.acme = lib.mkIf (cfg.role == "edge") {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
      certs.${cfg.primaryDomain} = {
        domain = cfg.primaryDomain;
        extraDomainNames = certExtraDomains;
        dnsProvider = "cloudflare";
        credentialsFile = cfg.cloudflareCredentialsFile;
        group = "caddy";
      };
    };

    services.caddy = lib.mkIf (cfg.role == "edge") {
      enable = true;
      configFile = caddyfile;
    };

    systemd.services.caddy = lib.mkIf (cfg.role == "edge") {
      wants = [ "acme-${cfg.primaryDomain}.service" ];
      after = [ "acme-${cfg.primaryDomain}.service" ];
    };
  };
}
