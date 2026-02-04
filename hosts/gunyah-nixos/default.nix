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

  # X11 on virtio-gpu (/dev/dri/card0) — rendered by crosvm to termux-x11
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    videoDrivers = [ "modesetting" ];
  };

  # Auto-login to XFCE (no display manager greeter)
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "bluesign";
    };
  };

  # Mesa for virtio-gpu (virgl 3D support)
  hardware.graphics.enable = true;

  # x11vnc — share the real X display over VNC (port 5901)
  systemd.services.x11vnc = {
    description = "x11vnc VNC server";
    after = [ "display-manager.service" ];
    requires = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.x11vnc}/bin/x11vnc"
        "-display :0"
        "-auth /var/run/lightdm/root/:0"
        "-forever -nopw -noshm"
        "-rfbport 5901"
        "-ncache 10 -ncache_cr"
        "-defer 10 -wait 10"
        "-threads"
      ];
      Restart = "on-failure";
      RestartSec = 5;
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
    chromium

    # VNC remote desktop
    tigervnc
    novnc
    python3Packages.websockify
    mesa-demos  # glxinfo/glxgears
  ];

  # User
  users.users.root.initialPassword = "nixos";

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  system.stateVersion = "25.11";
}
