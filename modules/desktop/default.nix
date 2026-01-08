# Desktop environment module (COSMIC + Niri)
{ config, lib, pkgs, ... }:

{
  imports = [
    ./cosmic-on-niri.nix
  ];

  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  services.displayManager.ly.enable = true;
  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";

  services.desktopManager.cosmic.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    alacritty
    niri
    (pkgs.callPackage ../../pkgs/cosmic-ext-alt/default.nix { })
  ];

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
}
