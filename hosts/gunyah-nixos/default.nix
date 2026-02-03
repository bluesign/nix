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

  # VM guest kernel modules
  boot.initrd.availableKernelModules = [
    "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_net"
    "virtio_console" "virtiofs" "9p" "9pnet" "9pnet_virtio"
  ];
  boot.initrd.supportedFilesystems = [ "virtiofs" ];
  boot.kernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" ];

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

  # X11 + XFCE4 desktop
  # XFCE is launched manually: DISPLAY=192.168.8.1:0 startxfce4
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
  };

  # Remote X11 to termux-x11 on the host device
  environment.variables.DISPLAY = "192.168.8.1:0";

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
  ];

  # User
  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
