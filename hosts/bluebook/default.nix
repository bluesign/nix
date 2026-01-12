# Host: bluebook (MacBook)
# To add a new host, copy this file to hosts/<hostname>/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/desktop
    ../../modules/flow
  ];

  networking.hostName = "bluebook";

  # Apple keyboard - make Fn keys work properly
  # fnmode=1: F1-F12 are media keys, hold Fn for function keys (Apple default)
  # fnmode=2: F1-F12 are function keys, hold Fn for media keys
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=1
  '';

  # CS8409 audio driver for MacBook internal speakers
  # The mainline driver doesn't initialize the Apple amplifiers properly
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../../pkgs/snd-hda-macbookpro { })
  ];

  # Preload sound modules at boot for reliable audio initialization
  boot.kernelModules = [
    "snd"              # ALSA core
    "snd_pcm"          # PCM support
    "snd_hwdep"        # Hardware dependent layer
    "snd_seq"          # MIDI sequencer
    "snd_hda_intel"    # Intel HDA controller
    "snd_hda_codec_cs8409"  # CS8409 codec (custom MacBook driver)
  ];

  # Enable firmware for audio codec
  hardware.enableAllFirmware = true;

  # Intel graphics - hardware video acceleration for Moonlight
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI driver for newer Intel (Broadwell+)
      intel-vaapi-driver    # Older VAAPI driver (fallback)
      vpl-gpu-rt            # Intel Quick Sync Video
    ];
  };

  # Use deep sleep (S3) instead of s2idle - more reliable on MacBooks
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # Lid and power button behavior
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    powerKey = "suspend";
  };

  # Power management
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;  # Intel thermal management

  # Ensure Bluetooth is unblocked at boot (rfkill can persist soft-block state)
  systemd.services.bluetooth-unblock = {
    description = "Unblock Bluetooth at boot";
    wantedBy = [ "bluetooth.service" ];
    before = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };

  # SSD health - periodic TRIM
  services.fstrim.enable = true;

  # Thunderbolt support
  services.hardware.bolt.enable = true;

  # FaceTime HD camera firmware
  hardware.facetimehd.enable = true;

  # Keyboard backlight support + power tools
  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop  # Battery diagnostics
    moonlight-qt  # Remote desktop client for Sunshine
  ];

  # Mount shared folder from blueminix via Tailscale
  # Uses automount - mounts on access, doesn't block boot if unavailable
  fileSystems."/home/bluesign/shared" = {
    device = "blueminix:/home/bluesign/shared";
    fsType = "nfs";
    options = [
      "x-systemd.automount"   # Mount on first access
      "x-systemd.idle-timeout=300"  # Unmount after 5min idle
      "x-systemd.mount-timeout=10"  # Don't wait long if unavailable
      "noauto"                # Don't mount at boot
      "nofail"                # Don't fail boot if unavailable
      "soft"                  # Return errors instead of hanging
      "timeo=30"              # 3 second timeout for operations
    ];
  };

  # Users enabled on this host
  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" ];
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
