{ lib, config, ... }:

let
  # Readable shorthand — derive these once.
  inherit (config) disko;
in

{
  # Make root partition size configurable from bootstrap-config.nix.
  # Accepts a value like "20G" or "100%" (fills remaining space).
  options disko-root-extra = lib.mkOption {
    type = lib.types.str;
    default = "20G";
    description = "Size for the root partition (e.g. \"20G\", \"50G\", \"100%\").";
  };

  disko.devices.disk.main = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        bios_grub = {
          size = "1M";
          type = "EF02";
        };

        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          size = lib.mkDefault config.disko-root-extra;
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = [
              "-L"
              "rootfs"
            ];
            mountpoint = "/";
          };
        };

        data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = [
              "-L"
              "srv-data"
            ];
            mountpoint = "/srv/data";
            mountOptions = [
              "nofail"
              "x-systemd.device-timeout=10s"
            ];
          };
        };
      };
    };
  };

  disko.devices.disk.media = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        media = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = [
              "-L"
              "srv-media"
            ];
            mountpoint = "/srv/media";
            mountOptions = [
              "nofail"
              "x-systemd.device-timeout=10s"
            ];
          };
        };
      };
    };
  };
}
