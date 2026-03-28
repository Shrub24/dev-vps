{ pkgs, ... }:
{
  imports = [
    ../../modules/services/tailscale.nix
    ../../modules/services/termix.nix
  ];

  systemd.services.tailscale-serve-termix = {
    description = "Expose Termix via Tailscale HTTPS /termix";
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
        ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=443 --set-path /termix http://127.0.0.1:8083
      '';
      ExecStop = ''
        ${pkgs.tailscale}/bin/tailscale serve --https=443 off /termix
      '';
    };
  };
}
