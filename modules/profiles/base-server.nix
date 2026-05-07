{ lib, ... }:
let
  globals = import ../../policy/globals.nix;
  nixPolicy = globals.services.nix or { };
in
{
  imports = [
    ../core/base.nix
    ./shell-profile.nix
    ../shared/host-recovery.nix
    ../services/tailscale.nix
    ../services/beszel-agent-auth.nix
    ../services/state-backups.nix
  ];

  networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  networking.firewall.trustedInterfaces = lib.mkAfter [ "tailscale0" ];

  nix.settings = {
    substituters = lib.mkAfter (nixPolicy.substituters or [ ]);
    trusted-substituters = lib.mkAfter (nixPolicy.trustedSubstituters or [ ]);
    trusted-public-keys = lib.mkAfter (nixPolicy.trustedPublicKeys or [ ]);
  };
}
