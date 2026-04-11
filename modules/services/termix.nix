{ lib, config, ... }:

{
  options.services.termix.dataDir = lib.mkOption {
    type = lib.types.str;
    default = "/srv/data/termix";
    description = "Data directory for Termix";
  };

  config = {
    virtualisation.podman.enable = true;

    virtualisation.oci-containers.containers = {
      guacd = {
        autoStart = true;
        image = "docker.io/guacamole/guacd:1.6.0";
        volumes = [
          "${config.services.termix.dataDir}/guacd:/var/lib/guacd"
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
          "0.0.0.0:8083:8080"
        ];
        extraOptions = [
          "--dns=100.100.100.100"
          "--dns=1.1.1.1"
          "--dns-search=tail0fe19b.ts.net"
        ];
        volumes = [
          "${config.services.termix.dataDir}/data:/app/data"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${config.services.termix.dataDir} 0750 root root - -"
      "d ${config.services.termix.dataDir}/data 0750 root root - -"
      "d ${config.services.termix.dataDir}/guacd 0750 root root - -"
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
  };
}
