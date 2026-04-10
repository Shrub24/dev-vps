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

  users.users.dev.extraGroups = lib.mkAfter [
    "beets"
    "music-ingest"
    "media"
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
    "a+ /srv/media/library - - - - user:syncthing:rwx"
    "a+ /srv/media/library - - - - default:user:syncthing:rwx"
    "f /srv/media/library/.stfolder 0664 syncthing syncthing - -"
    "d /srv/media/quarantine 2775 root music-ingest - -"
    "z /srv/media/quarantine 2775 root music-ingest - -"
    "a+ /srv/media/quarantine - - - - user:syncthing:rwx"
    "a+ /srv/media/quarantine - - - - default:user:syncthing:rwx"
    "f /srv/media/quarantine/.stfolder 0664 syncthing syncthing - -"
    "d /srv/media/quarantine/untagged 2775 root music-ingest - -"
    "z /srv/media/quarantine/untagged 2775 root music-ingest - -"
    "d /srv/media/quarantine/approved 2775 root music-ingest - -"
    "z /srv/media/quarantine/approved 2775 root music-ingest - -"
    "a+ /srv/media/quarantine/untagged - - - - group:media:r-x"
    "a+ /srv/media/quarantine/untagged - - - - default:group:media:r-X"
    "a+ /srv/media/quarantine/untagged - - - - user:syncthing:rwx"
    "a+ /srv/media/quarantine/untagged - - - - default:user:syncthing:rwx"
    "a+ /srv/media/quarantine/approved - - - - group:media:r-x"
    "a+ /srv/media/quarantine/approved - - - - default:group:media:r-X"
    "a+ /srv/media/quarantine/approved - - - - user:syncthing:rwx"
    "a+ /srv/media/quarantine/approved - - - - default:user:syncthing:rwx"
    "f /var/lib/slskd/environment 0640 slskd slskd - -"
  ];
}
