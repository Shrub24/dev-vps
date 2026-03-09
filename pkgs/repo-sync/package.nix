{
  lib,
  python3,
  python3Packages,
  writeShellApplication,
  git,
  gnugrep,
}: let
  python = python3.withPackages (ps: [ ps.pyyaml ]);
in
  writeShellApplication {
    name = "repo-sync";
    runtimeInputs = [ python git gnugrep ];
    text = ''
      exec ${python}/bin/python ${./repo-sync.py} "$@"
    '';
    meta = {
      description = "Sync project repos with private agent state mappings";
      platforms = lib.platforms.linux;
    };
  }
