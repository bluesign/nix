# User: bluesign
# To add a new user, copy this file to users/<username>/default.nix
{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    qtile = "qtile";
    rofi = "rofi";
    niri = "niri";
    fuzzel = "fuzzel";
    nvim = "nvim";
  };
in
{
  imports = [
    ../common
    ../../home/programs/alacritty.nix
  ];

  home = {
    username = "bluesign";
    homeDirectory = "/home/bluesign";
    stateVersion = "25.11";
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
    golangci-lint
    nil
    nixd
    nixpkgs-fmt

    # Apps
    google-chrome
    discord-ptb
  ];

  programs.git.settings = {
    user.name = "bluesign";
    user.email = "deniz@edincik.com";
  };
}
