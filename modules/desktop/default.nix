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
      ids = [ "*" "-keyd*" ];
      settings = {
        main = {
          # Caps Lock = Ctrl (tap for Escape, hold for modifier)
          capslock = "overload(control, esc)";
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

  # Blueman applet (bluetooth config is in hosts/common)
  services.blueman.enable = true;

  xdg.autostart.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
    ];
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      # niri supports both GNOME (Mutter.ScreenCast) and wlr portals
      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };
  };

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  # Font rendering for crisp text
  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting = {
      enable = true;
      style = "full";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };
}
