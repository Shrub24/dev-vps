{ ... }:
{
  services.navidrome = {
    enable = true;
    openFirewall = false;
    settings = {
      MusicFolder = "/srv/data/media";
      DataFolder = "/srv/data/navidrome";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/navidrome 0750 navidrome navidrome - -"
  ];

  systemd.services.navidrome = {
    wants = [ "network-online.target" "syncthing.service" ];
    after = [ "network-online.target" "syncthing.service" ];
  };
}
