{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.applications.admin;
  termixEnabled = config.services.admin.termix.enable;
  termixRoute = cfg.policyServices."termix-admin";
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.tailscale-serve-termix = lib.mkIf termixEnabled {
      description = "Expose Termix via dedicated Tailscale HTTPS port";
      requires = [
        "tailscaled.service"
        "podman-termix.service"
      ];
      wants = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "podman-termix.service"
      ];
      after = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "podman-termix.service"
      ];
      partOf = [
        "tailscaled.service"
        "podman-termix.service"
      ];
      restartIfChanged = true;
      stopIfChanged = true;
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=8443 ${termixRoute.upstream}
        '';
        ExecStop = ''
          ${pkgs.tailscale}/bin/tailscale serve --https=8443 off
        '';
      };
    };

  };
}
