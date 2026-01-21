# Common configuration shared across all hosts
{ config, lib, pkgs, ... }:

{
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Localization
  time.timeZone = "Europe/Amsterdam";

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

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

  # Sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

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

  # SSH server
  services.openssh.enable = true;

  # Power management (required for battery monitoring)
  services.upower.enable = true;

  # Zram swap (compressed RAM swap, better than disk)
  zramSwap.enable = true;

  # Early OOM killer (prevents system freeze on low memory)
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
  };

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
