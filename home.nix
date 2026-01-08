{ config, pkgs, ... }:

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

in {

  imports = [ ./programs/alacritty.nix ];

  programs.home-manager.enable = true;

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
    force = true;
  }) configs;

  home = {

    username = "bluesign";
    homeDirectory = "/home/bluesign";
    stateVersion = "25.11";

    packages = with pkgs; [
      #desktop 
      fuzzel
      bluetuith
      claude-code

      #dev
      cargo
      just
      unzip

      #neovim
      neovim
      ripgrep

      google-cloud-sdk
      go
      golangci-lint
      gh
      gcc
      nodejs
      nil
      nixd

      nixpkgs-fmt

      #utils
      google-chrome
      discord-ptb
    ];
  };

  programs.git = {
    extraConfig = {
      user.name = "bluesign";
      user.email = "deniz@edincik.com";
    };
    enable = true;
  };
  programs.gh = {
    enable = true;

    gitCredentialHelper = { enable = true; };
  };
}
