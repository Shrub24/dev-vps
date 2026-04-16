{
  config,
  lib,
  modulesPath,
  ...
}:
let
  webServicesPolicy = import ../../policy/web-services.nix;
  policyLib = import ../../lib/policy.nix { inherit lib; };

  resolvedRoutes = policyLib.resolveHostServices webServicesPolicy "do-admin-1";

  edgeRoutes = lib.mapAttrs (_: svc: {
    inherit (svc)
      subdomain
      path
      exposureMode
      category
      stripPrefix
      declarePublic
      upstream
      ;
    cloudflareAccessRequired = svc.access.requireCloudflareAccess;
    authenticatedOriginPullsRequired = svc.cloudflare.authenticatedOriginPulls;
  }) resolvedRoutes;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/profiles/base-server.nix
    ../../modules/profiles/worker-interface.nix
    ../../modules/applications/admin.nix
    ../../modules/applications/edge-ingress.nix
    ../../modules/providers/digitalocean/default.nix
    ../../modules/storage/disko-single-disk.nix
    ../../modules/core/users.nix
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "do-admin-1";
  disko.devices.disk.main.device = "/dev/vda";
  disko-root-extra = "100%";
  applications.admin.enable = true;
  applications.admin.dataRoot = "/srv/data";

  systemd.tmpfiles.rules = [
    "d ${config.applications.admin.dataRoot} 0755 root root - -"
    "z ${config.applications.admin.dataRoot} 0755 root root - -"
  ];

  sops.defaultSopsFile = ../../secrets/common.yaml;

  sops.secrets = lib.mkIf (builtins.pathExists ../../hosts/do-admin-1/secrets.yaml) {
    tailscale_auth_key = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "tailscale/auth_key";
      path = "/run/secrets/tailscale.auth_key";
      mode = "0400";
    };

    cloudflare_dns_api_token = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "cloudflare/dns_api_token";
      path = "/run/secrets/cloudflare.dns_api_token";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    pocket_id_encryption_key = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/encryption_key";
      path = "/run/secrets/pocket-id.encryption_key";
      owner = "pocket-id";
      group = "pocket-id";
      mode = "0400";
    };

    gatus_oidc_client_id = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/apps/gatus/client_id";
      path = "/run/secrets/pocket-id.gatus.client_id";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    gatus_oidc_client_secret = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/apps/gatus/client_secret";
      path = "/run/secrets/pocket-id.gatus.client_secret";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    termix_oidc_client_id = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/apps/termix/client_id";
      path = "/run/secrets/pocket-id.termix.client_id";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    termix_oidc_client_secret = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/apps/termix/client_secret";
      path = "/run/secrets/pocket-id.termix.client_secret";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    cloudflare_access_oidc_client_id = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "cloudflare_access/upstream_oidc/client_id";
      path = "/run/secrets/cloudflare-access.oidc.client_id";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    cloudflare_access_oidc_client_secret = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "cloudflare_access/upstream_oidc/client_secret";
      path = "/run/secrets/cloudflare-access.oidc.client_secret";
      owner = "root";
      group = "root";
      mode = "0400";
    };

  };

  sops.templates."caddy-cloudflare.env" =
    lib.mkIf (builtins.pathExists ../../hosts/do-admin-1/secrets.yaml)
      {
        owner = "root";
        group = "root";
        mode = "0400";
        content = ''
          CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare_dns_api_token}
        '';
      };

  sops.templates."gatus-oidc.env" =
    lib.mkIf (builtins.pathExists ../../hosts/do-admin-1/secrets.yaml)
      {
        owner = "root";
        group = "root";
        mode = "0400";
        content = ''
          GATUS_OIDC_CLIENT_ID=${config.sops.placeholder.gatus_oidc_client_id}
          GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder.gatus_oidc_client_secret}
        '';
      };

  sops.templates."termix-oidc.env" =
    lib.mkIf (builtins.pathExists ../../hosts/do-admin-1/secrets.yaml)
      {
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [
          "podman-termix.service"
        ];
        content = ''
          OIDC_CLIENT_ID=${config.sops.placeholder.termix_oidc_client_id}
          OIDC_CLIENT_SECRET=${config.sops.placeholder.termix_oidc_client_secret}
          OIDC_ISSUER_URL=https://id.shrublab.xyz
          OIDC_AUTHORIZATION_URL=https://id.shrublab.xyz/authorize
          OIDC_TOKEN_URL=https://id.shrublab.xyz/api/oidc/token
          OIDC_USERINFO_URL=https://id.shrublab.xyz/api/oidc/userinfo
          OIDC_SCOPES=openid email profile
        '';
      };

  services.tailscale = lib.mkIf (builtins.pathExists ../../hosts/do-admin-1/secrets.yaml) {
    authKeyFile = "/run/secrets/tailscale.auth_key";
  };

  services.resolved.enable = true;

  networking.firewall.trustedInterfaces = lib.mkAfter [
    "podman0"
    "cni-podman0"
  ];

  networking.nat = {
    enable = true;
    externalInterface = "ens3";
    internalInterfaces = [
      "podman0"
      "cni-podman0"
    ];
  };

  # Split DNS for Termix container traffic:
  # - tailnet names route to Tailscale MagicDNS
  # - everything else routes to public resolvers
  services.dnsmasq = {
    enable = true;
    settings = {
      no-resolv = true;
      server = [
        "/tail0fe19b.ts.net/100.100.100.100"
        "1.1.1.1"
        "8.8.8.8"
      ];
      "listen-address" = [
        "127.0.0.1"
        "10.88.0.1"
      ];
      "bind-dynamic" = true;
      "cache-size" = 1000;
    };
  };

  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  applications."edge-ingress" = lib.mkIf (builtins.pathExists ../../hosts/do-admin-1/secrets.yaml) {
    enable = true;
    role = "edge";
    primaryDomain = "shrublab.xyz";
    acmeEmail = "infra@shrublab.xyz";
    cloudflareCredentialsFile = config.sops.templates."caddy-cloudflare.env".path;
    authenticatedOriginPulls = {
      enable = true;
      caCertFile = toString ../../certs/authenticated_origin_pull_ca.pem;
    };
    routes = edgeRoutes;
  };

  system.stateVersion = "25.11";
}
