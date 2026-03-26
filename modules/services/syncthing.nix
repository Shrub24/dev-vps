{ ... }:
{
  services.syncthing = {
    enable = true;
    dataDir = "/srv/data/media";
    configDir = "/srv/data/syncthing/config";
    openDefaultPorts = false;
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/syncthing 0750 syncthing syncthing - -"
    "d /srv/data/syncthing/config 0750 syncthing syncthing - -"
    "d /srv/data/media 0775 syncthing syncthing - -"
    "d /srv/data/inbox 0775 syncthing syncthing - -"
  ];
}
