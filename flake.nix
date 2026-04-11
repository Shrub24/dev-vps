{
  description = "Modular NixOS fleet infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      disko,
      sops-nix,
      deploy-rs,
      ...
    }:
    let
      devShellSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      mkDevShell =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            just
            git
            jq
            yq
            sops
            age
            nixos-anywhere
            deploy-rs.packages.${system}.default
            nix-output-monitor
            nixfmt
            statix
            ssh-to-age
          ];
        };

      deployConfig = import ./lib/deploy {
        inherit self nixpkgs deploy-rs;
        hosts = import ./lib/deploy/hosts.nix;
      };
    in
    {
      devShells = nixpkgs.lib.genAttrs devShellSystems (system: {
        default = mkDevShell system;
      });

      packages = nixpkgs.lib.genAttrs devShellSystems (system: {
        deploy-rs = deploy-rs.packages.${system}.default;
      });

      nixosConfigurations.oci-melb-1 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/oci-melb-1/default.nix
        ];
        specialArgs = { inherit self inputs; };
      };

      nixosConfigurations.do-admin-1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/do-admin-1/default.nix
        ];
        specialArgs = { inherit self inputs; };
      };

      deploy = deployConfig.deploy;
      checks = deployConfig.checks;
    };
}
