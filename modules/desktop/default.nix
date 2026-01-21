# Desktop environment module (Niri + Ags)
{ config, lib, pkgs, ... }:

{
  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  # Enable keyd for key remapping
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          # Caps Lock = Super (tap for Escape, hold for modifier)
          capslock = "overload(meta, esc)";
          # Swap Left Meta and Left Control
          leftmeta = "leftcontrol";
          leftcontrol = "leftmeta";
        };
      };
    };
  };

  services.displayManager.ly.enable = true;
  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    alacritty
    niri
    playerctl
    brightnessctl
    swaylock              # Screen locker
    swayidle              # Idle management
    swaybg                # Wallpaper
  ];

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  xdg.autostart.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        # Use GNOME portal for screen sharing (niri implements org.gnome.Mutter.ScreenCast)
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };
  };

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
}
