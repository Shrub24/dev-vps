{ ... }:
{
  imports = [
    ../../modules/services/syncthing.nix
    ../../modules/services/navidrome.nix
    ../../modules/services/slskd.nix
  ];

  users.groups.music-ingest = { };

  users.users.slskd.extraGroups = [ "music-ingest" ];

  services.slskd = {
    domain = "oci-melb-1";
    environmentFile = "/var/lib/slskd/environment";
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/inbox 2775 root music-ingest - -"
    "f /var/lib/slskd/environment 0640 slskd slskd - -"
  ];
}
