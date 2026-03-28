{
  hostName = "oci-melb-1";
  bootstrapUser = "ubuntu";
  bootstrapDisk = "/dev/sda";
  rootPartitionSize = "20G";
  flake = "path:.#oci-melb-1";
  hardwareConfigGenerator = "nixos-generate-config";
  hardwareConfigPath = "hosts/oci-melb-1/hardware-configuration.nix";
}
