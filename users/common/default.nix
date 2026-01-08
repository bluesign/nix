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
  ];

  programs.git.enable = true;
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
