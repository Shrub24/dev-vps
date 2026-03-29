{ ... }:
{
  services.syncthing = {
    enable = true;
    dataDir = "/srv/data/media";
    configDir = "/srv/data/syncthing/config";
    openDefaultPorts = false;
    settings.folders."media" = {
      path = "/srv/data/media";
      type = "sendreceive";
      versioning = {
        type = "trashcan";
        params = {
          cleanoutDays = "30";
          cleanupIntervalS = "86400";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/syncthing 0750 syncthing syncthing - -"
    "d /srv/data/syncthing/config 0750 syncthing syncthing - -"
    "d /srv/data/media 0775 syncthing syncthing - -"
  ];
}
