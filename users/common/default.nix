# Common user configuration - applied to all users
{ config, lib, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Dev tools
    cargo
    just
    unzip
    ripgrep
    gcc
    nodejs

    # Utils
    gh
    xdg-utils
  ];

  programs.git.enable = true;
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      open = "xdg-open";
      icat = "kitty +kitten icat";
      img = "chafa -f kitty";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      open = "xdg-open";
      icat = "kitty +kitten icat";
      img = "chafa -f kitty";
      vim = "nvim";
    };
    history = {
      size = 100000;
      save = 100000;
      share = true;          # Share history between sessions live
      ignoreDups = true;     # Don't store duplicate commands
      ignoreSpace = true;    # Don't store commands starting with space
      extended = true;       # Save timestamps
    };
  };
}
