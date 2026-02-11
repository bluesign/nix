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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
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
    firefox
    fuzzel
    bluetuith
    claude-code
    nemo-with-extensions  # Includes GVFS support for network locations
    grim          # Wayland screenshot tool
    slurp         # Area selection for Wayland
    swappy        # GUI annotation tool
    wf-recorder   # Wayland screen recorder (wf-recorder -g "$(slurp)" -f out.mp4)
    wl-clipboard  # Wayland clipboard (wl-copy, wl-paste)
    yazi          # Terminal file manager with image preview
    imv           # Fast Wayland image viewer
    wl-kbptr      # Keyboard pointer control for Wayland

    # Dev
    neovim
    gemini-cli
    sqlite
    google-cloud-sdk
    go
    gopls
    jq
    delta         # Beautiful git diffs
    difftastic    # Structural diff tool
    gh-dash       # GitHub dashboard TUI
    (pkgs.callPackage ../../pkgs/golangci-lint { })
    (pkgs.callPackage ../../pkgs/putio { })
    gnumake
    cmake
    pkg-config
    file
    nil
    nixd
    nixpkgs-fmt
    (python3.withPackages (ps: with ps; [ requests pypdf reportlab ]))
    pipx          # Install Python apps in isolated environments

    # Apps
    ytui-music    # YouTube Music TUI player
    chawan        # Terminal web browser
    nchat         # Terminal WhatsApp/Telegram client
    aerc          # Terminal email client

    # Media
    mpv           # Video player (includes libmpv)
    yt-dlp        # YouTube downloader (maintained fork of youtube-dl)
    v4l-utils     # Camera tools (v4l2-ctl for testing webcams)

    # Sixel graphics
    libsixel      # img2sixel - convert images to sixel
    chafa         # Image viewer with sixel support

    # Secrets
    gnupg
    pass

    # System
    btop          # Resource monitor with GPU support
    ncdu          # Interactive disk usage analyzer

    # Networking
    nmap

    # RF/SDR
    python312Packages.rfcat  # PandwaRF / Yard Stick One control

    # Android
    valent          # KDE Connect protocol (notifications, clipboard, files)
    scrcpy          # Screen mirroring and control
    android-tools   # ADB for device communication
    sshfs           # SFTP filesystem mount (required for Valent phone browsing)
  ] ++ lib.optionals stdenv.hostPlatform.isx86_64 [
    # x86_64-only packages
    vscode
    google-chrome
    discord-ptb
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

  # Font scaling for larger text system-wide
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      text-scaling-factor = 1.1;
    };
  };

}
