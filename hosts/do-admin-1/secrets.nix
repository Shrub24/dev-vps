{
  config,
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

    quantum_oidc_client_id = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/apps/quantum/client_id";
      path = "/run/secrets/pocket-id.quantum.client_id";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    quantum_oidc_client_secret = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "pocket_id/apps/quantum/client_secret";
      path = "/run/secrets/pocket-id.quantum.client_secret";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    admin_ssh_identity = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "admin/ssh/identity";
      path = "/run/secrets/admin.ssh.identity";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    admin_ssh_known_hosts = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "admin/ssh/known_hosts";
      path = "/run/secrets/admin.ssh.known_hosts";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    quantum_admin_password = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "quantum/admin_password";
      path = "/run/secrets/quantum.admin_password";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    cockpit_service_user_password_hash = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "cockpit/service_user/password_hash";
      path = "/run/secrets/cockpit.service_user.password_hash";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_tailscale_device_id = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/tailscale/device_id";
      path = "/run/secrets/homepage.tailscale.device_id";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_tailscale_api_key = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/tailscale/api_key";
      path = "/run/secrets/homepage.tailscale.api_key";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_navidrome_user = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/navidrome/user";
      path = "/run/secrets/homepage.navidrome.user";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_navidrome_token = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/navidrome/token";
      path = "/run/secrets/homepage.navidrome.token";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_navidrome_salt = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/navidrome/salt";
      path = "/run/secrets/homepage.navidrome.salt";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_slskd_key = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/slskd/key";
      path = "/run/secrets/homepage.slskd.key";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_beszel_username = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/beszel/username";
      path = "/run/secrets/homepage.beszel.username";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    homepage_beszel_password = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "homepage/beszel/password";
      path = "/run/secrets/homepage.beszel.password";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    vaultwarden_admin_token = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "vaultwarden/admin_token";
      path = "/run/secrets/vaultwarden.admin_token";
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };

    vaultwarden_smtp_username = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "vaultwarden/smtp_username";
      path = "/run/secrets/vaultwarden.smtp_username";
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };

    vaultwarden_smtp_password = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "vaultwarden/smtp_password";
      path = "/run/secrets/vaultwarden.smtp_password";
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };

    vaultwarden_push_installation_id = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "vaultwarden/push_installation_id";
      path = "/run/secrets/vaultwarden.push_installation_id";
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };

    vaultwarden_push_installation_key = {
      sopsFile = ../../hosts/do-admin-1/secrets.yaml;
      key = "vaultwarden/push_installation_key";
      path = "/run/secrets/vaultwarden.push_installation_key";
      owner = "vaultwarden";
      group = "vaultwarden";
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

  sops.templates."termix-oidc.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      OIDC_CLIENT_ID=${config.sops.placeholder.termix_oidc_client_id}
      OIDC_CLIENT_SECRET=${config.sops.placeholder.termix_oidc_client_secret}
      OIDC_ISSUER_URL=${config.services.admin.pocket-id.oidc.issuerUrl}
      OIDC_AUTHORIZATION_URL=${config.services.admin.pocket-id.oidc.authorizationUrl}
      OIDC_TOKEN_URL=${config.services.admin.pocket-id.oidc.tokenUrl}
      OIDC_USERINFO_URL=${config.services.admin.pocket-id.oidc.userinfoUrl}
      OIDC_SCOPES=openid email profile
    '';
  };

  sops.templates."quantum-oidc.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      FILEBROWSER_OIDC_CLIENT_ID=${config.sops.placeholder.quantum_oidc_client_id}
      FILEBROWSER_OIDC_CLIENT_SECRET=${config.sops.placeholder.quantum_oidc_client_secret}
    '';
  };

  sops.templates."quantum-auth.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      FILEBROWSER_ADMIN_PASSWORD=${config.sops.placeholder.quantum_admin_password}
    '';
  };

  sops.templates."homepage-auth.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      HOMEPAGE_VAR_TAILSCALE_DEVICEID=${config.sops.placeholder.homepage_tailscale_device_id}
      HOMEPAGE_VAR_TAILSCALE_API_KEY=${config.sops.placeholder.homepage_tailscale_api_key}
      HOMEPAGE_VAR_NAVIDROME_USER=${config.sops.placeholder.homepage_navidrome_user}
      HOMEPAGE_VAR_NAVIDROME_TOKEN=${config.sops.placeholder.homepage_navidrome_token}
      HOMEPAGE_VAR_NAVIDROME_SALT=${config.sops.placeholder.homepage_navidrome_salt}
      HOMEPAGE_VAR_SLSKD_KEY=${config.sops.placeholder.homepage_slskd_key}
      HOMEPAGE_VAR_BESZEL_USER=${config.sops.placeholder.homepage_beszel_username}
      HOMEPAGE_VAR_BESZEL_PASSWORD=${config.sops.placeholder.homepage_beszel_password}
    '';
  };

  sops.templates."vaultwarden.env" = {
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0400";
    content = ''
      ADMIN_TOKEN='${config.sops.placeholder.vaultwarden_admin_token}'
      SMTP_USERNAME=${config.sops.placeholder.vaultwarden_smtp_username}
      SMTP_PASSWORD=${config.sops.placeholder.vaultwarden_smtp_password}
      PUSH_INSTALLATION_ID=${config.sops.placeholder.vaultwarden_push_installation_id}
      PUSH_INSTALLATION_KEY=${config.sops.placeholder.vaultwarden_push_installation_key}
    '';
  };

  services.tailscale = {
    authKeyFile = "/run/secrets/tailscale.auth_key";
  };
}
