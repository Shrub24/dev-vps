{ lib, ... }:
let
  bootstrapConfig = import ../../../hosts/oci-melb-1/bootstrap-config.nix;
in
{
  disko.devices.disk.main.device = lib.mkDefault bootstrapConfig.bootstrapDisk;

  boot.loader.grub.devices = [ bootstrapConfig.bootstrapDisk ];

  # Keep OCI serial-console recovery available after reboot.
  # Provider-specific console wiring intentionally lives here.
  boot.kernelParams = [ "console=ttyAMA0,115200n8" ];

  systemd.services."serial-getty@ttyAMA0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };
}
