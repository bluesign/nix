# User: bluesign
# To add a new user, copy this file to users/<username>/default.nix
{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    qtile = "qtile";
    rofi = "rofi";
    fuzzel = "fuzzel";
    nvim = "nvim";
  };
in
{
  imports = [
    ../common
    ../../home/programs/alacritty.nix
    ../../home/programs/niri.nix
  ];

  home = {
    username = "bluesign";
    homeDirectory = "/home/bluesign";
    stateVersion = "25.11";
    enableNixpkgsReleaseCheck = false;
    backupFileExtension = "hm-backup";  # Avoid "existing backup" conflicts
  };

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
    force = true;
  }) configs;

  # User-specific packages
  home.packages = with pkgs; [
    # Desktop
    fuzzel
    bluetuith
    claude-code

    # Dev
    neovim
    google-cloud-sdk
    go
    gopls
    jq
    (pkgs.callPackage ../../pkgs/golangci-lint { })
    gnumake
    cmake
    pkg-config
    file
    nil
    nixd
    nixpkgs-fmt
    (python3.withPackages (ps: with ps; [ requests ]))

    # Apps
    google-chrome
    discord-ptb
  ];

  programs.git.settings = {
    user.name = "bluesign";
    user.email = "deniz@edincik.com";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
}
