{
  lib,
  config,
  ...
}:
let
  cfg = config.services.slskd;
  downloadsParent = builtins.dirOf cfg.downloadsPath;
  incompleteParent = builtins.dirOf cfg.incompletePath;
in
{
  options.services.slskd.downloadsPath = lib.mkOption {
    type = lib.types.str;
    default = "/srv/media/inbox/slskd";
    description = "Directory for completed slskd downloads.";
  };

  options.services.slskd.incompletePath = lib.mkOption {
    type = lib.types.str;
    default = "/srv/media/slskd-incomplete";
    description = "Directory for incomplete slskd downloads.";
  };

  config = {
    services.slskd = {
      enable = true;
      openFirewall = false;
      settings = {
        directories = {
          downloads = cfg.downloadsPath;
          incomplete = cfg.incompletePath;
        };
        shares.directories = [
          "/srv/media/library"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadsPath} 0775 slskd music-ingest - -"
      "z ${cfg.downloadsPath} 0775 slskd music-ingest - -"
      "d ${cfg.incompletePath} 0775 slskd music-ingest - -"
      "z ${cfg.incompletePath} 0775 slskd music-ingest - -"
    ];

    systemd.services.slskd = {
      unitConfig.RequiresMountsFor = [
        cfg.downloadsPath
        cfg.incompletePath
      ];
      wants = [
        "network-online.target"
        "syncthing.service"
      ];
      after = [
        "srv-media.mount"
        "network-online.target"
        "syncthing.service"
      ];
      serviceConfig.ReadWritePaths = lib.mkAfter (
        lib.unique [
          "/srv/media"
          downloadsParent
          incompleteParent
          cfg.downloadsPath
          cfg.incompletePath
        ]
      );
      serviceConfig.PrivateMounts = lib.mkForce false;
      serviceConfig.ProtectSystem = lib.mkForce "off";
      serviceConfig.SupplementaryGroups = lib.mkAfter [
        "music-ingest"
        "media"
      ];
    };
  };
}
