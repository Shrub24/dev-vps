{ ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/profiles/base-server.nix
    ../../modules/services/tailscale.nix
  ];

  networking.hostName = "oci-melb-1";
  system.stateVersion = "25.11";
}
