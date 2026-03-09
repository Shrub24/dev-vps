{ config, pkgs, ... }: {
  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zshrc";
    envExtra = ''
      : ''${ZSH_MOBILE:=1}
      export ZSH_MOBILE
      export ANTIDOTE_ZSH="${pkgs.antidote}/share/antidote/antidote.zsh"
    '';
  };

  xdg.enable = true;
  xdg.configFile."zshrc" = {
    source = ../zshrc;
    recursive = true;
  };

}
