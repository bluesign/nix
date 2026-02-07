# bluesign user for gunyah-nixos VM
# CLI tools + niri Wayland compositor
{ config, lib, pkgs, ... }:

{
  imports = [
    ../common
    ../../home/programs/tmux.nix
    ../../home/programs/niri-gunyah.nix
    ../../home/programs/dms.nix
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

    # GPU
    vulkan-tools

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

  # DMS: auto-start on default.target (graphical-session.target doesn't activate
  # when niri is launched directly by greetd rather than through systemd)
  systemd.user.services.dms.Install.WantedBy = lib.mkForce [ "default.target" ];
  systemd.user.services.dms.Unit.After = lib.mkForce [ "default.target" ];
  systemd.user.services.dms.Unit.PartOf = lib.mkForce [ "default.target" ];

  programs.gpg.enable = true;

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
    };
  };
}
