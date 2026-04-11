{
  hostName = "do-admin-1";
  bootstrapUser = "root";
  bootstrapDisk = "/dev/vda";
  rootPartitionSize = "100%";
  dataRoot = "/srv/data";
  mediaRoot = "/srv/media";
  flake = "path:.#do-admin-1";
  hardwareConfigGenerator = "nixos-generate-config";
  hardwareConfigPath = "hosts/do-admin-1/hardware-configuration.nix";
}
