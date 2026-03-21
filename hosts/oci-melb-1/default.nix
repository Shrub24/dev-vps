{ ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/profiles/base-server.nix
    ../../modules/services/tailscale.nix
    ../../modules/providers/oci/default.nix
    ../../modules/storage/disko-root.nix
  ];

  networking.hostName = "oci-melb-1";
  system.stateVersion = "25.11";
}
