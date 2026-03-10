{ pkgs, ... }:
{
  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    gh
    vim
    neovim
    tmux
    ripgrep
    fd
    jq
    fzf
    bat
    zoxide
    pay-respects
    antidote
    eza
    duf
    tree
    lsof
    strace
    rsync
    unzip
    zip
    gnumake
    gcc
    pkg-config
    cmake
    ninja
    python3
    python3Packages.pyyaml
    nodejs
    bun
    go
    rustc
    cargo
    opencode
  ];

  xdg.enable = true;
  xdg.configFile."zshrc" = {
    source = ../zshrc;
    recursive = true;
    force = true;
  };

  home.file.".zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zshrc"
    : ''${ZSH_MOBILE:=1}
    export ZSH_MOBILE
    export ANTIDOTE_ZSH="${pkgs.antidote}/share/antidote/antidote.zsh"
  '';

  systemd.user.services.codenomad = {
    Unit = {
      Description = "CodeNomad Server";
      ConditionPathExists = "/run/secrets/codenomad.env";
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "/home/dev";
      EnvironmentFile = "/run/secrets/codenomad.env";
      Environment = [
        "HOME=/home/dev"
        "USER=dev"
        "LOGNAME=dev"
        "SHELL=${pkgs.zsh}/bin/zsh"
        "XDG_CONFIG_HOME=/home/dev/.config"
        "XDG_CACHE_HOME=/home/dev/.cache"
        "XDG_DATA_HOME=/home/dev/.local/share"
        "PATH=/home/dev/.nix-profile/bin:/etc/profiles/per-user/dev/bin:/run/current-system/sw/bin"
        "CLI_UI_NO_UPDATE=true"
        "CLI_UI_AUTO_UPDATE=false"
      ];
      ExecStart = "${pkgs.codenomad}/bin/codenomad --host 127.0.0.1 --https false --http true --http-port 9899 --workspace-root /home/dev/workspaces --ui-no-update --ui-auto-update false";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

}
