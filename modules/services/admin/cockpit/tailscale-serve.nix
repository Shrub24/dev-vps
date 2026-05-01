{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.admin.cockpit;
  tailscaleServe = cfg.tailscaleServe;
  localUrl = "http://127.0.0.1:${toString config.services.cockpit.port}";
in
{
  config = lib.mkIf (cfg.enable && tailscaleServe.enable) {
    systemd.services.tailscale-serve-cockpit = {
      description = "Expose Cockpit via dedicated Tailscale HTTPS port";
      requires = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      wants = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      after = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      partOf = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      stopIfChanged = true;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=${toString tailscaleServe.port} ${localUrl}
        '';
        ExecStop = ''
          ${pkgs.tailscale}/bin/tailscale serve --https=${toString tailscaleServe.port} off
        '';
      };
    };
  };
}
