{ lib, ... }:
let
  bootstrapConfig = import ../../../hosts/oci-melb-1/bootstrap-config.nix;
in
{
  disko.devices.disk.main.device = lib.mkDefault bootstrapConfig.bootstrapDisk;

  boot.loader.grub.devices = [ bootstrapConfig.bootstrapDisk ];
}
