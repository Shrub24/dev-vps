{
  self,
  nixpkgs,
  deploy-rs,
  hosts,
}:
let
  lib = nixpkgs.lib;

  deployNode = name: host: {
    hostname = host.hostName;
    sshUser = host.sshUser;
    profiles.system = {
      user = "root";
      remoteBuild = true;
      path = deploy-rs.lib.${host.system}.activate.nixos self.nixosConfigurations.${name};
    };
  };

  systems = lib.unique (lib.attrValues (lib.mapAttrs (_: host: host.system) hosts));
  deploy = {
    nodes = lib.mapAttrs deployNode hosts;
  };
in
{
  inherit deploy;

  checks = lib.genAttrs systems (system: deploy-rs.lib.${system}.deployChecks deploy);
}
