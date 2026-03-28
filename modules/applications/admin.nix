{ pkgs, ... }:
{
  imports = [
    ../../modules/services/tailscale.nix
    ../../modules/services/termix.nix
  ];

  systemd.services.tailscale-serve-termix = {
    description = "Expose Termix via dedicated Tailscale HTTPS port";
    wants = [
      "tailscaled.service"
      "podman-termix.service"
    ];
    after = [
      "tailscaled.service"
      "podman-termix.service"
    ];
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
}
