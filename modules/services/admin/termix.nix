{
  lib,
  config,
  ...
}:
let
  appCfg = config.applications.admin;
  cfg = config.services.admin.termix;
in
{
  options.services.admin.termix.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable admin-owned Termix composition wiring.";
  };

  config = lib.mkIf appCfg.enable {
    services.termix.enable = lib.mkDefault cfg.enable;
  };
}
