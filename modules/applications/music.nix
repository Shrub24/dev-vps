{ ... }:
{
  imports = [
    ../../modules/services/syncthing.nix
    ../../modules/services/navidrome.nix
    ../../modules/services/slskd.nix
  ];

  services.slskd = {
    domain = "oci-melb-1";
    environmentFile = "/var/lib/slskd/environment";
  };

  systemd.tmpfiles.rules = [
    "f /var/lib/slskd/environment 0640 slskd slskd - -"
  ];
}
