{ config, lib, ... }:
let
  globals = import ../../policy/globals.nix;
  nixPolicy = globals.services.nix or { };
  cfg = config.fleet.hostIdentity;
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

  options.fleet.hostIdentity.sshPrivateKeyFile = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Host-scoped SOPS file containing the dev user SSH identity private key.";
  };

  config = {
    networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
    networking.firewall.trustedInterfaces = lib.mkAfter [ "tailscale0" ];

    nix.settings = {
      substituters = lib.mkAfter (nixPolicy.substituters or [ ]);
      trusted-substituters = lib.mkAfter (nixPolicy.trustedSubstituters or [ ]);
      trusted-public-keys = lib.mkAfter (nixPolicy.trustedPublicKeys or [ ]);
    };

    programs.ssh.extraConfig = lib.mkIf (cfg.sshPrivateKeyFile != null) ''
      Host *
        IdentityFile /run/secrets/host.ssh_identity
        IdentitiesOnly yes
    '';

    sops.secrets = lib.mkIf (cfg.sshPrivateKeyFile != null) {
      host_ssh_identity = {
        sopsFile = cfg.sshPrivateKeyFile;
        key = "identity/ssh_private_key";
        path = "/run/secrets/host.ssh_identity";
        mode = "0400";
      };
    };
  };
}
