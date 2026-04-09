{ ... }:
{
  services.syncthing = {
    enable = true;
    dataDir = "/srv/media";
    configDir = "/srv/data/syncthing/config";
    openDefaultPorts = false;
    settings.folders."media" = {
      path = "/srv/media";
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
  ];
}
