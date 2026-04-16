{
  config,
  lib,
  ...
}:
{
  sops.defaultSopsFile = ../../secrets/common.yaml;

  sops.secrets = {
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

  sops.templates."caddy-cloudflare.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare_dns_api_token}
    '';
  };

  sops.templates."gatus-oidc.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      GATUS_OIDC_CLIENT_ID=${config.sops.placeholder.gatus_oidc_client_id}
      GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder.gatus_oidc_client_secret}
    '';
  };

  sops.templates."termix-oidc.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      OIDC_CLIENT_ID=${config.sops.placeholder.termix_oidc_client_id}
      OIDC_CLIENT_SECRET=${config.sops.placeholder.termix_oidc_client_secret}
      OIDC_ISSUER_URL=${config.applications.admin.policyServices."pocket-id-admin".publicUrl}
      OIDC_AUTHORIZATION_URL=${
        config.applications.admin.policyServices."pocket-id-admin".publicUrl
      }/authorize
      OIDC_TOKEN_URL=${
        config.applications.admin.policyServices."pocket-id-admin".publicUrl
      }/api/oidc/token
      OIDC_USERINFO_URL=${
        config.applications.admin.policyServices."pocket-id-admin".publicUrl
      }/api/oidc/userinfo
      OIDC_SCOPES=openid email profile
    '';
  };

  services.tailscale = {
    authKeyFile = "/run/secrets/tailscale.auth_key";
  };
}
