{
  oci-melb-1 = {
    hostName = "oci-melb-1";
    # hostName = "161.33.71.82";
    sshUser = "dev";
    system = "aarch64-linux";
    remoteBuild = true;
  };

  do-admin-1 = {
    hostName = "homelab-lon";
    # hostName = "139.59.199.81";
    sshUser = "dev";
    system = "x86_64-linux";
    remoteBuild = false;
  };
}
