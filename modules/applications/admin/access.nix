{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.applications.admin;
  termixEnabled = config.services.admin.termix.enable;
  cockpitEnabled = config.services.admin.cockpit.enable;
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

    systemd.services.tailscale-serve-cockpit = lib.mkIf cockpitEnabled {
      description = "Expose Cockpit via dedicated Tailscale HTTPS port";
      requires = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      wants = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "cockpit.socket"
      ];
      after = [
        "tailscaled-autoconnect.service"
        "tailscaled.service"
        "cockpit.socket"
      ];
      partOf = [
        "tailscaled.service"
        "cockpit.socket"
      ];
      restartIfChanged = true;
      stopIfChanged = true;
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=9443 http://127.0.0.1:${toString config.services.cockpit.port}
        '';
        ExecStop = ''
          ${pkgs.tailscale}/bin/tailscale serve --https=9443 off
        '';
      };
    };

  };
}
