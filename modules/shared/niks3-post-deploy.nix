{
  config,
  lib,
  pkgs,
  ...
}:
let
  hook = config.services.niks3-auto-upload;
  hookPkg = hook.package;
in
{
  config = lib.mkIf hook.enable {
    nix.settings.post-build-hook = lib.mkForce "";

    systemd.paths.niks3-post-deploy = {
      wantedBy = [ "paths.target" ];
      pathConfig = {
        PathChanged = "/run/current-system";
        Unit = "niks3-post-deploy.service";
      };
    };

    systemd.services.niks3-post-deploy = {
      description = "Queue current system closure for niks3 upload";
      path = [ hookPkg ];
      serviceConfig = {
        Type = "oneshot";
        ProtectSystem = "strict";
        PrivateTmp = true;
      };
      environment = {
        OUT_PATHS = "/run/current-system";
      };
      script = ''
        exec ${lib.getExe' hookPkg "niks3-hook"} send
      '';
    };
  };
}
