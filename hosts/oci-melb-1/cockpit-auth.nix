{ config, lib, ... }:
{
  services.admin.cockpit.serviceUser = {
    enable = true;
    name = "cockpit-svc";
    denySsh = true;
    hashedPasswordFile = config.sops.secrets.cockpit_service_user_password_hash.path;
  };

  services.admin.cockpit.publicHost = lib.mkForce "cockpit.shrublab.xyz";
  services.admin.cockpit.urlRoot = lib.mkForce "/oci-melb-1";
  services.admin.cockpit.tailscaleServe.enable = true;
}
