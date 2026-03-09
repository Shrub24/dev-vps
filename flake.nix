{
  description = "Reproducible NixOS dev VPS with disko + nixos-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    ...
  }: let
    system = "x86_64-linux";

    overlay = final: prev: {
      codenomad = prev.buildNpmPackage rec {
        pname = "codenomad";
        version = "0.12.1";

        src = prev.fetchurl {
          url = "https://registry.npmjs.org/@neuralnomads/codenomad/-/codenomad-${version}.tgz";
          hash = "sha512-L9f7YAXTiS7YUpUvLBGBtJcvy0nwjSKPeaGsMPmjdZl8bksFMuYtVZJ57Z18m3JGqhYXcB8H2WL2FR3jXuXZSw==";
        };

        npmDepsHash = "sha256-oFtZX5eCpuTUhL1rH39jYRhtsCk3GxVG5WQ7kXumYOY=";
        dontNpmBuild = true;
        npmInstallFlags = [ "--ignore-scripts" "--omit=dev" ];

        postPatch = ''
          cp ${./codenomad-package-lock.json} package-lock.json
        '';

        nativeBuildInputs = [ prev.makeWrapper ];

        installPhase = ''
          runHook preInstall

          mkdir -p "$out/lib/node_modules/@neuralnomads/codenomad"
          cp -R . "$out/lib/node_modules/@neuralnomads/codenomad"

          mkdir -p "$out/bin"
          makeWrapper ${prev.nodejs}/bin/node "$out/bin/codenomad" \
            --add-flags "$out/lib/node_modules/@neuralnomads/codenomad/dist/bin.js"

          runHook postInstall
        '';

        meta = with prev.lib; {
          description = "CodeNomad server for OpenCode sessions";
          homepage = "https://github.com/NeuralNomadsAI/CodeNomad";
          license = licenses.mit;
          platforms = platforms.linux;
          mainProgram = "codenomad";
        };
      };
    };
  in {
    packages.${system}.codenomad =
      (import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      }).codenomad;

    nixosConfigurations.dev-vps = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        diskDevice = "/dev/vda";
      };
      modules = [
        {nixpkgs.overlays = [ overlay ];}
        disko.nixosModules.disko
        ./disko-config.nix
        ./configuration.nix
      ];
    };
  };
}
