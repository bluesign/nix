# Host: blueminix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/desktop
    ../../modules/flow
  ];

  networking.hostName = "blueminix";

  # WirePlumber config for EliteMini (no internal speakers)
  # Enable HDMI audio auto-profile since this mini PC only has HDMI and headphone jack
  services.pipewire.wireplumber.extraConfig."50-blueminix-audio" = {
    "monitor.alsa.rules" = [
      {
        matches = [{ "device.name" = "alsa_card.pci-0000_c4_00.1"; }];
        actions.update-props = {
          "api.acp.auto-profile" = true;
          "api.acp.auto-port" = true;
        };
      }
    ];
  };

  # NFS server for shared folder (Tailscale only)
  services.nfs.server = {
    enable = true;
    exports = ''
      /home/bluesign/shared  100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # Open NFS ports for Tailscale interface
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
  };

  # Sunshine remote desktop server
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for Wayland capture
    openFirewall = true;
    settings = {
      # Stream at bluebook's native resolution to avoid scaling artifacts
      dd_resolution_option = "manual";
      dd_manual_resolution = "2560x1600";
    };
  };

  # Steam gaming platform
  programs.steam.enable = true;

  # uinput access for Sunshine virtual input devices
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';
  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;  # Creates uinput group and sets up permissions

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" "uinput" ];  # uinput group for Sunshine
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
