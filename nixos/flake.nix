{
  description = "Reproducible NixOS dev VPS with CodeNomad + Tailscale";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix/17eea6f3816ba6568b8c81db8a4e6ca438b30b7c";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";

    overlay = final: prev: {
      codenomad = prev.callPackage ./pkgs/codenomad/package.nix {};
      opencode = prev.callPackage ./pkgs/opencode/package.nix {};
    };

    pkgs = import nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  in {
    packages.${system} = {
      inherit (pkgs) codenomad opencode;
    };

    nixosConfigurations.dev-vps = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        diskDevice = "/dev/vda";
      };
      modules = [
        {nixpkgs.overlays = [ overlay ];}
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./nixos/disko-config.nix
        ./nixos/configuration.nix
      ];
    };
  };
}
