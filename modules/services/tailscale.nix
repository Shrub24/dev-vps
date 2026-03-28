{ ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = false;
    extraSetFlags = [ "--ssh" ];
  };
}
