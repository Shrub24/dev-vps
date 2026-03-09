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
      repo-sync = prev.callPackage ./pkgs/repo-sync/package.nix {};
    };

    pkgs = import nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  in {
    packages.${system} = {
      inherit (pkgs) codenomad opencode repo-sync;
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
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
        ./nixos/configuration.nix
      ];
    };
  };
}
