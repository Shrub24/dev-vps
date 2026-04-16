{
  lib,
  config,
  ...
}:
let
  cfg = config.applications.admin;
in
{
  imports = [
    ../../services/termix.nix
    ../../services/pocket-id.nix
    ../../services/admin/termix.nix
    ../../services/admin/pocket-id.nix
    ../../services/admin/cockpit.nix
    ../../services/admin/webhook.nix
    ../../services/admin/ntfy.nix
    ../../services/admin/gatus/default.nix
    ../../services/admin/vaultwarden.nix
    ../../services/admin/filebrowser.nix
    ../../services/admin/homepage/default.nix
    ../../services/admin/beszel.nix
    ./identity.nix
    ./access.nix
  ];

  options.applications.admin = {
    enable = lib.mkEnableOption "admin application composition";

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data";
      description = "Top-level data root for admin application services.";
    };

    policyServices = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Resolved host services from policy/web-services.nix for SSOT endpoint consumption.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.admin = {
      termix.enable = lib.mkDefault true;
      pocket-id.enable = lib.mkDefault true;
      cockpit.enable = lib.mkDefault true;
      webhook.enable = lib.mkDefault true;
      ntfy.enable = lib.mkDefault true;
      gatus.enable = lib.mkDefault true;
      vaultwarden.enable = lib.mkDefault true;
      filebrowser.enable = lib.mkDefault false;
      homepage.enable = lib.mkDefault true;
      beszel.enable = lib.mkDefault true;
    };
  };
}
