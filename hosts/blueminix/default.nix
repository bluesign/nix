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

  # AMD Radeon 780M graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For Steam/gaming
  };

  # Thunderbolt/USB4 support
  services.hardware.bolt.enable = true;

  # Firmware updates (BIOS, devices)
  services.fwupd.enable = true;

  # SSD TRIM for NVMe health
  services.fstrim.enable = true;

  # WirePlumber config for EliteMini (no internal speakers, headphone jack only)
  # Set the ALC269VC analog output as default audio sink
  services.pipewire.wireplumber.extraConfig."50-blueminix-audio" = {
    "monitor.alsa.rules" = [
      {
        matches = [{ "device.name" = "alsa_card.pci-0000_c4_00.6"; }];
        actions.update-props = {
          # Higher priority to be selected as default
          "priority.driver" = 2000;
          "priority.session" = 2000;
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
  # hidraw access for user (HID devices like keyboards, mice, etc.)
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users"
  '';
  boot.kernelModules = [ "uinput" ];

  # Fix headphone jack detection for ALC269VC codec
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=,dell-headset-multi patch=,/etc/hda-jack-fix.fw
  '';

  # HDA patch to force headphone output on ALC269VC
  # - Disable jack detection so headphones are always available
  # - Pin 0x15 is the headphone output
  environment.etc."hda-jack-fix.fw".text = ''
    [codec]
    0x10ec0269 0x1f4cb016 0

    [hint]
    jack_detect = no
  '';
  hardware.uinput.enable = true;  # Creates uinput group and sets up permissions

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" "uinput" ];  # uinput group for Sunshine
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
