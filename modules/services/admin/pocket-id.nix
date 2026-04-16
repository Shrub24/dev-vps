{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.pocket-id;
in
{
  options.services.admin.pocket-id.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Pocket ID composition wiring.";
  };

  config = lib.mkIf appCfg.enable {
    services.shrublab-pocket-id.enable = lib.mkDefault cfg.enable;
  };
}
