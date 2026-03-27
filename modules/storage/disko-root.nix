{ lib, ... }:
let
  bootstrapConfig = import ../../hosts/oci-melb-1/bootstrap-config.nix;
in
{
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
          size = lib.mkDefault bootstrapConfig.rootPartitionSize;
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
}
