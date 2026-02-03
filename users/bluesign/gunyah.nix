# Lightweight bluesign user for gunyah-nixos VM
# No Wayland/niri/dms — just CLI tools + XFCE-compatible packages
{ config, lib, pkgs, ... }:

{
  imports = [
    ../common
    ../../home/programs/tmux.nix
  ];

  home = {
    username = "bluesign";
    homeDirectory = "/home/bluesign";
    stateVersion = "25.11";
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  home.packages = with pkgs; [
    # Dev
    neovim
    sqlite
    go
    gopls
    jq
    delta
    difftastic
    gh-dash
    gnumake
    cmake
    pkg-config
    file
    nil
    nixd
    nixpkgs-fmt
    (python3.withPackages (ps: with ps; [ requests pypdf reportlab ]))
    pipx

    # Apps
    chawan
    aerc

    # Media
    mpv
    yt-dlp

    # Sixel
    libsixel
    chafa

    # Secrets
    gnupg
    pass

    # System
    btop
    ncdu

    # Networking
    nmap
    sshfs
  ];

  programs.git.settings = {
    user.name = "bluesign";
    user.email = "deniz@edincik.com";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.gpg.enable = true;

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
    };
  };
}
