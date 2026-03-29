{ ... }:
{
  services.slskd = {
    enable = true;
    openFirewall = false;
    settings = {
      directories = {
        downloads = "/srv/data/inbox/slskd";
        incomplete = "/srv/data/slskd/incomplete";
      };
      shares.directories = [
        "/srv/media"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/inbox/slskd 0775 slskd music-ingest - -"
    "d /srv/data/slskd 0775 slskd music-ingest - -"
    "d /srv/data/slskd/incomplete 0775 slskd music-ingest - -"
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
