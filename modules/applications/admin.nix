{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.applications.admin;
in
{
  imports = [
    ../../modules/services/termix.nix
  ];

  options.applications.admin.dataRoot = lib.mkOption {
    type = lib.types.str;
    default = "/srv/data";
    description = "Top-level data root for admin application services.";
  };

  config.services.termix.dataDir = "${cfg.dataRoot}/termix";

  config.systemd.services.tailscale-serve-termix = {
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
        ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=8443 http://127.0.0.1:8083
      '';
      ExecStop = ''
        ${pkgs.tailscale}/bin/tailscale serve --https=8443 off
      '';
    };
  };

  config.system.activationScripts.tailscale-serve-termix-restart = {
    deps = [ "etc" ];
    text = ''
      ${pkgs.systemd}/bin/systemctl restart tailscale-serve-termix.service || true
    '';
  };
}
