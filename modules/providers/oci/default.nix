{ lib, ... }:
{
  disko.devices.disk.main.device = lib.mkDefault "/dev/vda";

  boot.loader.grub.devices = [ "/dev/vda" ];
}
