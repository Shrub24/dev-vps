{ ... }:
{
  services.syncthing = {
    enable = true;
    dataDir = "/srv/data/syncthing";
    configDir = "/srv/data/syncthing/config";
    openDefaultPorts = false;
    settings.devices."laptop" = {
      id = "L43OT2A-IULZ4LG-YRFMARJ-EX2CDF3-ZYTXGEX-UGWAYE6-K46I3BA-3KZF2AE";
    };
    settings.folders."media" = {
      path = "/srv/media/library";
      type = "sendreceive";
      versioning = {
        type = "trashcan";
        params = {
          cleanoutDays = "30";
          cleanupIntervalS = "86400";
        };
      };
    };
    settings.folders."quarantine" = {
      path = "/srv/media/quarantine";
      type = "sendreceive";
      devices = [ "laptop" ];
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
