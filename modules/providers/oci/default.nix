{ lib, ... }:
{
  disko.devices.disk.main.device = lib.mkDefault "/dev/vda";
}
