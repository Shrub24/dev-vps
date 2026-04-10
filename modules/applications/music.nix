{ lib, ... }:
{
  imports = [
    ../../modules/services/syncthing.nix
    ../../modules/services/navidrome.nix
    ../../modules/services/slskd.nix
    ../../modules/services/beets-inbox.nix
  ];

  users.groups.music-ingest = { };
  users.groups.media = { };
  users.groups.remediation = { };

  users.users.dev.extraGroups = lib.mkAfter [
    "beets"
    "music-ingest"
    "media"
    "remediation"
  ];

  services.slskd = {
    domain = "oci-melb-1";
    environmentFile = "/var/lib/slskd/environment";
  };

  systemd.tmpfiles.rules = [
    "d /srv/media 0755 root root - -"
    "z /srv/media 0755 root root - -"
    "d /srv/media/inbox 2775 root music-ingest - -"
    "z /srv/media/inbox 2775 root music-ingest - -"
    "d /srv/media/library 2775 root media - -"
    "z /srv/media/library 2775 root media - -"
    "d /srv/media/library/tagged 2775 root media - -"
    "z /srv/media/library/tagged 2775 root media - -"
    "d /srv/media/library/untagged 2775 root remediation - -"
    "z /srv/media/library/untagged 2775 root remediation - -"
    "a+ /srv/media/library/untagged - - - - group:media:r-x"
    "a+ /srv/media/library/untagged - - - - default:group:media:r-x"
    "f /var/lib/slskd/environment 0640 slskd slskd - -"
  ];
}
