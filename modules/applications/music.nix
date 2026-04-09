{ lib, ... }:
{
  imports = [
    ../../modules/services/syncthing.nix
    ../../modules/services/navidrome.nix
    ../../modules/services/slskd.nix
    ../../modules/services/beets-inbox.nix
  ];

  users.groups.music-ingest = { };
  users.groups.music-library = { };

  users.users.dev.extraGroups = lib.mkAfter [
    "music-ingest"
    "music-library"
  ];

  services.slskd = {
    domain = "oci-melb-1";
    environmentFile = "/var/lib/slskd/environment";
  };

  systemd.tmpfiles.rules = [
    "z /srv/media 2775 syncthing music-library - -"
    "d /srv/media/inbox 2775 root music-ingest - -"
    "z /srv/media/inbox 2775 root music-ingest - -"
    "f /var/lib/slskd/environment 0640 slskd slskd - -"
  ];
}
