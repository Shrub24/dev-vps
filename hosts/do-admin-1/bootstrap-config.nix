{
  hostName = "do-admin-1";
  bootstrapUser = "root";
  bootstrapDisk = "/dev/vda";
  flake = "path:.#do-admin-1";
  hardwareConfigGenerator = "nixos-generate-config";
  hardwareConfigPath = "hosts/do-admin-1/hardware-configuration.nix";
}
