{ ... }:
{
  services.slskd = {
    enable = true;
    openFirewall = false;
    settings = {
      directories = {
        downloads = "/srv/media/inbox/slskd";
        incomplete = "/srv/media/slskd/incomplete";
      };
      shares.directories = [
        "/srv/media"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/media/inbox/slskd 0775 slskd music-ingest - -"
    "d /srv/media/slskd 0775 slskd music-ingest - -"
    "d /srv/media/slskd/incomplete 0775 slskd music-ingest - -"
  ];

  systemd.services.slskd = {
    wants = [
      "network-online.target"
      "syncthing.service"
    ];
    after = [
      "network-online.target"
      "syncthing.service"
    ];
  };
}
