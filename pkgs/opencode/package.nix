{
  buildNpmPackage,
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
}:
buildNpmPackage rec {
  pname = "opencode-ai";
  version = "1.2.24";

  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-ai/-/opencode-ai-${version}.tgz";
    hash = "sha512-LaSoATkVEF6jyXNnAPrkqYpmHsZfuf2uPLDSEGJkL4hT6HYFq8LkoknHDjCGIiE5Be3MmId4+l17eSIKDfmddw==";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-0UwKt9N2TWNxnV1t85VL36CMsB/vNpAJtwQVHnwMWkI=";
  dontNpmBuild = true;
  npmInstallFlags = [
    "--ignore-scripts"
    "--omit=dev"
  ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules/opencode-ai"
    cp -R . "$out/lib/node_modules/opencode-ai"

    mkdir -p "$out/bin"
    makeWrapper ${nodejs}/bin/node "$out/bin/opencode" \
      --add-flags "$out/lib/node_modules/opencode-ai/bin/opencode"

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode CLI agent harness";
    homepage = "https://github.com/sst/opencode";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "opencode";
  };
}
