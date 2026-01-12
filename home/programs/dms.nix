{ config, lib, pkgs, ... }:

{
  programs.dankMaterialShell = {
    enable = true;
    systemd.enable = true;
    systemd.restartIfChanged = true;
  };

  # Additional packages that were bundled with waybar config
  home.packages = with pkgs; [
    networkmanager
    pwvucontrol
    pavucontrol
    blueman
    libnotify
    power-profiles-daemon
    curl
    jq
  ];
}
