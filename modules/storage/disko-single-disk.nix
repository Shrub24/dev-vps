{ lib, config, ... }:
{
  options."disko-root-extra" = lib.mkOption {
    type = lib.types.str;
    default = "100%";
    description = "Size for the root partition on single-disk hosts.";
  };

  config.disko.devices.disk.main = {
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
      };
    };
  };
}
