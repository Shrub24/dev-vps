{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.vaultwarden;
  vaultRoute = appCfg.policyServices."vaultwarden-admin";
  vaultHost = vaultRoute.origin.host;
  vaultPort = vaultRoute.origin.port;
in
{
  options.services.admin.vaultwarden = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable admin-owned Vaultwarden service wiring.";
    };

    smtpFrom = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "From address for Vaultwarden emails. Set per-host (e.g. you@gmail.com).";
    };
  };

  config = lib.mkIf (appCfg.enable && cfg.enable) {
    assertions = [
      {
        assertion = cfg.smtpFrom != null;
        message = "services.admin.vaultwarden.smtpFrom must be set (the email Vaultwarden sends from).";
      }
    ];

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";

      config = {
        # ── Domain & reverse proxy ──
        DOMAIN = vaultRoute.publicUrl;
        ROCKET_ADDRESS = vaultHost;
        ROCKET_PORT = vaultPort;
        IP_HEADER = "X-Forwarded-For";

        # ── Access control ──
        SIGNUPS_ALLOWED = false;
        SIGNUPS_VERIFY = true;
        INVITATIONS_ALLOWED = true;
        ORG_CREATION_USERS = "none";

        # ── Features ──
        SENDS_ALLOWED = true;
        WEB_VAULT_ENABLED = true;
        ENABLE_WEBSOCKET = true;
        EXPERIMENTAL_CLIENT_FEATURE_FLAGS = "ssh-key-vault-item,ssh-agent";
        EMERGENCY_ACCESS_ALLOWED = true;

        # ── Push notifications ──
        PUSH_ENABLED = true;

        # ── Security hardening ──
        PASSWORD_ITERATIONS = 600000;
        PASSWORD_HINTS_ALLOWED = true;
        LOGIN_RATELIMIT_SECONDS = 60;
        LOGIN_RATELIMIT_MAX_BURST = 10;
        ADMIN_RATELIMIT_SECONDS = 300;
        ADMIN_RATELIMIT_MAX_BURST = 3;
        ADMIN_SESSION_LIFETIME = 20;

        # ── SMTP (non-secret settings) ──
        SMTP_HOST = "smtp.resend.com";
        SMTP_FROM = cfg.smtpFrom;
        SMTP_FROM_NAME = "Vaultwarden";
        SMTP_PORT = 587;
        SMTP_SECURITY = "starttls";

        # ── Housekeeping ──
        EVENTS_DAYS_RETAIN = 30;
        LOG_LEVEL = "info";
        EXTENDED_LOGGING = true;
        LOG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%3f";
      };

      environmentFile = config.sops.templates."vaultwarden.env".path;
    };
  };
}
