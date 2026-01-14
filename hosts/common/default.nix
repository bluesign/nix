# Common configuration shared across all hosts
{ config, lib, pkgs, ... }:

{
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Localization
  time.timeZone = "Europe/Amsterdam";

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  # Shell
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "z" "fzf" "sudo" "terraform" "systemadmin" "vi-mode" ];
  };
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  # Core packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    fzf
    htop
    overskride
  ];

  # Services
  services.dbus.enable = true;
  services.dbus.implementation = "broker";

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Tailscale VPN
  services.tailscale.enable = true;

  # Power management (required for battery monitoring)
  services.upower.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
}
