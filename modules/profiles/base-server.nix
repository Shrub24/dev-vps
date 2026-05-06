{ lib, ... }:
{
  imports = [
    ../core/base.nix
    ./shell-profile.nix
    ../services/tailscale.nix
    ../services/beszel-agent-auth.nix
    ../services/state-backups.nix
  ];

  networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  networking.firewall.trustedInterfaces = lib.mkAfter [ "tailscale0" ];
}
