{ ... }:
{
  services.slskd = {
    enable = true;
    openFirewall = false;
    settings = {
      directories = {
        downloads = "/srv/data/inbox/slskd/complete";
        incomplete = "/srv/data/inbox/slskd/incomplete";
      };
      shares.directories = [
        "/srv/data/media"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/inbox/slskd 0775 slskd music-ingest - -"
    "d /srv/data/inbox/slskd/complete 0775 slskd music-ingest - -"
    "d /srv/data/inbox/slskd/incomplete 0775 slskd music-ingest - -"
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
