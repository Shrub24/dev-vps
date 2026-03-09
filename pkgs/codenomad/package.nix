{
  buildNpmPackage,
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
}: buildNpmPackage rec {
  pname = "codenomad";
  version = "0.12.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@neuralnomads/codenomad/-/codenomad-${version}.tgz";
    hash = "sha512-L9f7YAXTiS7YUpUvLBGBtJcvy0nwjSKPeaGsMPmjdZl8bksFMuYtVZJ57Z18m3JGqhYXcB8H2WL2FR3jXuXZSw==";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-oFtZX5eCpuTUhL1rH39jYRhtsCk3GxVG5WQ7kXumYOY=";
  dontNpmBuild = true;
  npmInstallFlags = [ "--ignore-scripts" "--omit=dev" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules/@neuralnomads/codenomad"
    cp -R . "$out/lib/node_modules/@neuralnomads/codenomad"

    mkdir -p "$out/bin"
    makeWrapper ${nodejs}/bin/node "$out/bin/codenomad" \
      --add-flags "$out/lib/node_modules/@neuralnomads/codenomad/dist/bin.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "CodeNomad server for OpenCode sessions";
    homepage = "https://github.com/NeuralNomadsAI/CodeNomad";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "codenomad";
  };
}
