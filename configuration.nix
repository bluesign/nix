# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "sudo" "terraform" "systemadmin" "vi-mode" ];
  };

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.xwayland.enable = true;
  services.displayManager.ly.enable = true;
  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP =
    "X-NIXOS-SYSTEMD-AWARE";

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    xwayland-satellite
    alacritty
    niri
    (pkgs.callPackage ./cosmic-ext-alt.nix { })
    (pkgs.callPackage ./pkgs/flow-cli/default.nix { })
  ];

  services.desktopManager.cosmic.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  xdg.autostart.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-cosmic

    ];
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  system.stateVersion = "25.11"; # Did you read the comment?
  nix.settings.experimental-features = "nix-command flakes";
}
