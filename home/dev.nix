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

}
