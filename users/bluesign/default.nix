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
    chawan = "chawan";
    nchat = "nchat";
  };
in
{
  imports = [
    ../common
    ../../home/programs/alacritty.nix
    ../../home/programs/kitty.nix
    ../../home/programs/niri.nix
    ../../home/programs/dms.nix
    ../../home/programs/tmux.nix
  ];

  home = {
    username = "bluesign";
    homeDirectory = "/home/bluesign";
    stateVersion = "25.11";
    # Clean up old backup files before activation to prevent "would be clobbered" errors
    activation.cleanupBackups = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      find ~/.config -name "*.hm-backup" -delete 2>/dev/null || true
    '';
    sessionVariables = {
      EDITOR = "nvim";
      NCHAT_IMAGES = "1";  # Enable kitty image support in nchat
    };
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
    nemo
    grim          # Wayland screenshot tool
    slurp         # Area selection for Wayland
    swappy        # GUI annotation tool

    # Dev
    neovim
    sqlite
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
    (python3.withPackages (ps: with ps; [ requests pypdf reportlab ]))

    # Apps
    google-chrome
    discord-ptb
    chawan        # Terminal web browser
    nchat         # Terminal WhatsApp/Telegram client

    # Sixel graphics
    libsixel      # img2sixel - convert images to sixel
    chafa         # Image viewer with sixel support

    # Voice input
    wtype  # Wayland text input
    (pkgs.callPackage ../../pkgs/whisper-input { })
  ];

  programs.git.settings = {
    user.name = "bluesign";
    user.email = "deniz@edincik.com";
  };

}
