{ lib, config, ... }:
let
  hostName = config.networking.hostName;
in
{
  systemd.services.tailscaled-autoconnect.wants = [ "sops-install-secrets.service" ];
  systemd.services.tailscaled-autoconnect.after = [ "sops-install-secrets.service" ];

  services.tailscale = {
    enable = true;
    openFirewall = false;
    extraSetFlags = [ "--ssh" ];
    extraUpFlags = lib.mkDefault [
      "--hostname=${hostName}"
      "--advertise-tags=tag:${hostName}"
    ];
  };
}
