{ ... }:
{
  services.slskd = {
    enable = true;
    openFirewall = false;
    settings = {
      directories = {
        downloads = "/srv/data/inbox/complete";
        incomplete = "/srv/data/inbox/incomplete";
      };
      shares.directories = [
        "/srv/data/media"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/inbox 0775 slskd slskd - -"
    "d /srv/data/inbox/complete 0775 slskd slskd - -"
    "d /srv/data/inbox/incomplete 0775 slskd slskd - -"
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
