{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = false;
    settings = {
      MusicFolder = "/srv/media";
      DataFolder = "/srv/data/navidrome";
      Address = "0.0.0.0";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/navidrome 0750 navidrome navidrome - -"
  ];

  systemd.services.navidrome = {
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
