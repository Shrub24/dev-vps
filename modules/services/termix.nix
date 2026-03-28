{ ... }:
{
  virtualisation.podman.enable = true;

  virtualisation.oci-containers.containers = {
    guacd = {
      autoStart = true;
      image = "docker.io/guacamole/guacd:1.5.5";
      volumes = [
        "/srv/data/termix/guacd:/var/lib/guacd"
      ];
    };

    termix = {
      autoStart = true;
      image = "ghcr.io/termix-official/termix:latest";
      dependsOn = [ "guacd" ];
      environment = {
        TERMIX_GUACD_HOST = "127.0.0.1";
        TERMIX_GUACD_PORT = "4822";
      };
      ports = [
        "8083:8080"
      ];
      volumes = [
        "/srv/data/termix/data:/var/lib/termix"
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
