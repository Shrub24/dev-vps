{ lib, config, pkgs, ... }:
let
  cfg = config.services.navidrome;
in
{
  services.navidrome = {
    enable = true;
    openFirewall = false;
    settings = {
      MusicFolder = "/srv/media/library";
      DataFolder = "/srv/data/navidrome";
      PlaylistsPath = "playlists";
      AutoImportPlaylists = false;
      ScanSchedule = "15m";
      EnableTranscodingConfig = true;
      DefaultDownsamplingFormat = "opus";
      TranscodingCacheSize = "2GB";
      FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
      Address = "0.0.0.0";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/media/library/playlists 0775 root media - -"
    "C /srv/media/library/playlists/needs-attention-untagged.nsp 0644 root media - ${../../scripts/navidrome-needs-attention-untagged.nsp}"
  ];

  # Override nixpkgs-generated navidromeDirs so MusicFolder (/srv/media/library)
  # is not tmpfiles-managed by navidrome.
  systemd.tmpfiles.settings.navidromeDirs = lib.mkForce {
    "${cfg.settings.DataFolder or "/var/lib/navidrome"}"."d" = {
      mode = "700";
      user = cfg.user;
      group = cfg.group;
    };
    "${cfg.settings.CacheFolder or "/var/lib/navidrome/cache"}"."d" = {
      mode = "700";
      user = cfg.user;
      group = cfg.group;
    };
  };

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
