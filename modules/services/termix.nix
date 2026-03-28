{ ... }:
{
  virtualisation.podman.enable = true;

  virtualisation.oci-containers.containers = {
    guacd = {
      autoStart = true;
      image = "docker.io/guacamole/guacd:1.6.0";
      volumes = [
        "/srv/data/termix/guacd:/var/lib/guacd"
      ];
    };

    termix = {
      autoStart = true;
      image = "ghcr.io/lukegus/termix:release-2.0.0";
      dependsOn = [ "guacd" ];
      environment = {
        GUACD_HOST = "127.0.0.1";
        GUACD_PORT = "4822";
      };
      ports = [
        "127.0.0.1:8083:8080"
      ];
      volumes = [
        "/srv/data/termix/data:/app/data"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/data/termix 0750 root root - -"
    "d /srv/data/termix/data 0750 root root - -"
    "d /srv/data/termix/guacd 0750 root root - -"
  ];

  systemd.services."podman-guacd" = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  systemd.services."podman-termix" = {
    wants = [
      "network-online.target"
      "podman-guacd.service"
    ];
    after = [
      "network-online.target"
      "podman-guacd.service"
    ];
  };
}
