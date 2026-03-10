{
  lib,
  runCommand,
  symlinkJoin,
  python3,
  python3Packages,
  writeShellApplication,
  git,
  gh,
  gnugrep,
}: let
  python = python3.withPackages (ps: [ ps.pyyaml ]);
  app = writeShellApplication {
    name = "repo-sync";
    runtimeInputs = [ python git gh gnugrep ];
    text = ''
      exec ${python}/bin/python ${./repo-sync.py} "$@"
    '';
  };

  completionFiles = runCommand "repo-sync-completions" {} ''
    mkdir -p $out/share/zsh/site-functions
    mkdir -p $out/share/bash-completion/completions
    cp ${./_repo-sync} $out/share/zsh/site-functions/_repo-sync
    cp ${./repo-sync.bash} $out/share/bash-completion/completions/repo-sync
  '';
in
  symlinkJoin {
    name = "repo-sync";
    paths = [ app completionFiles ];
    meta = {
      description = "Sync project repos with private agent state mappings";
      platforms = lib.platforms.linux;
    };
  }
