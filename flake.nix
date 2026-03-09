{
  description = "Reproducible NixOS dev VPS with CodeNomad + Tailscale";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    disko,
    sops-nix,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";

    overlay = final: prev: {
      codenomad = prev.callPackage ./pkgs/codenomad/package.nix {};
      opencode = prev.callPackage ./pkgs/opencode/package.nix {};
      repo-sync = prev.callPackage ./pkgs/repo-sync/package.nix {};
    };

    pkgs = import nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };

    unstablePkgs = import nixpkgs-unstable {
      inherit system;
      overlays = [ overlay ];
    };
  in {
    packages.${system} = {
      inherit (pkgs) codenomad opencode repo-sync;
    };

    devShells.${system}.default = unstablePkgs.mkShell {
      packages = with unstablePkgs; [
        just
        git
        jq
        yq
        sops
        age
        nixos-anywhere
        nix-output-monitor
      ];
    };

    nixosConfigurations.dev-vps = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./nixos/digitalocean.nix
        {nixpkgs.overlays = [ overlay ];}
        disko.nixosModules.disko
        {disko.devices.disk.main.device = "/dev/vda";}
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.dev = import ./home/dev.nix;
        }
        ./nixos/configuration.nix
      ];
    };
  };
}
