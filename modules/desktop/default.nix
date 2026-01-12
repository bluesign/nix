# Desktop environment module (Niri + Ags)
{ config, lib, pkgs, ... }:

{
  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  # Enable keyd for tap-vs-hold modifier behavior
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          # Tap Super = Super+O (toggle-overview), Hold = normal Super modifier
          meta = "overload(meta, M-o)";
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
      xdg-desktop-portal
      xdg-desktop-portal-gtk
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
