{
  description = "Modular NixOS fleet infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      disko,
      sops-nix,
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
            nix-output-monitor
            nixfmt
            statix
          ];
        };
    in
    {
      devShells = nixpkgs.lib.genAttrs devShellSystems (system: {
        default = mkDevShell system;
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
    };
}
