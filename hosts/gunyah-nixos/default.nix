# Host: gunyah-nixos — NixOS VM for Gunyah/crosvm on OnePlus 13
# Standalone lightweight VM config — does NOT import ../common or ../../modules/desktop
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "gunyah-nixos";

  # No bootloader — crosvm provides kernel directly
  boot.loader.grub.enable = false;

  # Custom Gunyah kernel has everything built-in, no modules needed in initrd
  boot.initrd.availableKernelModules = lib.mkForce [];
  boot.initrd.kernelModules = lib.mkForce [];
  boot.initrd.includeDefaultModules = false;
  boot.initrd.supportedFilesystems = lib.mkForce [ "ext4" ];
  boot.kernelModules = [];

  # Console for crosvm serial
  boot.kernelParams = [ "console=hvc0" ];

  # Static networking: .3 for NixOS, .2 for Debian, .1 for host
  networking = {
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.8.3";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.8.1";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    firewall.enable = false;
  };

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  # Shell
  programs.zsh.enable = true;

  # SSH server
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Niri Wayland compositor on virtio-gpu
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = let
        niri-run = pkgs.writeShellScript "niri-run" ''
          unset DISPLAY
          export LIBSEAT_BACKEND=seatd
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
            pkgs.xorg.libXcursor pkgs.xorg.libXi pkgs.xorg.libXrandr
            pkgs.xorg.libX11 pkgs.xorg.libXext pkgs.xorg.libXrender
            pkgs.xorg.libXfixes pkgs.xorg.libxcb pkgs.xorg.libXinerama
          ]}
          exec ${pkgs.niri}/bin/niri
        '';
      in "${niri-run}";
      user = "bluesign";
    };
  };

  # seatd for seat management
  services.seatd = {
    enable = true;
    group = "video";
  };

  # Terminal
  environment.variables.TERMINAL = "foot";

  # XDG portal for niri (uses GNOME portal)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # Mesa for virtio-gpu (gfxstream Vulkan + Zink for GL)
  hardware.graphics.enable = true;

  # gfxstream Vulkan ICD for Vulkan apps; desktop GL uses virgl (stable)
  # Per-app gfxstream: MESA_LOADER_DRIVER_OVERRIDE=zink glxgears
  environment.variables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/gfxstream_vk_icd.aarch64.json";
  };

  # udev rules: seat tags for input devices, DRM/input permissions
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", TAG+="seat"
    SUBSYSTEM=="input", KERNEL=="event*", MODE="0666"
    SUBSYSTEM=="drm", MODE="0666"
  '';

  # Ensure /run/user/1000 exists for XDG_RUNTIME_DIR
  systemd.tmpfiles.rules = [
    "d /run/user/1000 0700 bluesign users -"
  ];

  # Disable kernel keyboard autorepeat (crosvm X11 input has delayed key releases)
  systemd.services.disable-autorepeat = {
    description = "Disable kernel keyboard autorepeat for crosvm";
    after = [ "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-autorepeat" ''
        for dev in /dev/input/event*; do
          ${pkgs.perl}/bin/perl -e 'use POSIX; my $rep = pack("LL", 10000, 100); ioctl(STDIN, 0x40084503, $rep)' < "$dev" 2>/dev/null || true
        done
      '';
    };
  };

  # Required by home-manager xdg portal config (from niri/desktop modules in user profile)
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Sudo without password
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    firefox

    # Niri desktop
    niri
    xwayland-satellite
    foot              # terminal
    xterm             # fallback terminal
    grim              # screenshots
    slurp             # region select
    wl-clipboard      # clipboard

    # GPU/display tools
    mesa-demos        # glxinfo/glxgears
    vulkan-tools
    glmark2
    evtest
    wev

    # X11 libs for niri runtime
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXfixes
    xorg.libxcb
    xorg.libXinerama

    # VNC remote desktop
    novnc
    python3Packages.websockify
  ];

  # User
  users.users.root.initialPassword = "nixos";

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  system.stateVersion = "25.11";
}
