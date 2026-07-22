# Host: bluex (ThinkPad X1 Carbon Gen 14 — Intel)
# Full desktop clone of blueminix, adapted for Intel laptop hardware.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/desktop
    ../../modules/flow
    ../../modules/gamedev
  ];

  networking.hostName = "bluex";

  # Enable aarch64 emulation for cross-building (gunyah-nixos VM) — like blueminix
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # ThinkPad X1 Carbon Gen 14 is very new Intel hardware — the default 25.11
  # kernel (6.12) may lack working graphics/DRM for its GPU, which breaks the
  # niri session. Use the latest kernel + all firmware for GPU/Wi-Fi support.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableAllFirmware = true;

  # Intel graphics - hardware video acceleration + 32-bit for Steam
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For Steam/gaming
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI driver for newer Intel (Broadwell+)
      intel-vaapi-driver    # Older VAAPI driver (fallback)
      vpl-gpu-rt            # Intel Quick Sync Video
    ];
  };

  # Laptop power management
  services.thermald.enable = true;             # Intel thermal management
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "suspend";
  };

  # Thunderbolt/USB4 support
  services.hardware.bolt.enable = true;

  # Firmware updates (BIOS, devices)
  services.fwupd.enable = true;

  # SSD TRIM for NVMe health
  services.fstrim.enable = true;

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

  # Laptop power tools + remote desktop client
  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop     # Battery diagnostics
    lm_sensors   # Temperature monitoring (run: sensors)
    moonlight-qt # Remote desktop client for Sunshine
  ];

  # Trust Tailscale interface (matches blueminix)
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
  };

  # Mount shared folder from blueminix via Tailscale (client, not server).
  # Automount - mounts on access, doesn't block boot if unavailable.
  fileSystems."/home/bluesign/shared" = {
    device = "blueminix:/home/bluesign/shared";
    fsType = "nfs";
    options = [
      "x-systemd.automount"          # Mount on first access
      "x-systemd.idle-timeout=300"   # Unmount after 5min idle
      "x-systemd.mount-timeout=10"   # Don't wait long if unavailable
      "noauto"                       # Don't mount at boot
      "nofail"                       # Don't fail boot if unavailable
      "soft"                         # Return errors instead of hanging
      "timeo=30"                     # Timeout for operations
    ];
  };

  # Sunshine remote desktop server - override common config
  services.sunshine.settings = {
    dd_resolution_option = lib.mkForce "disabled";  # Don't auto-change resolution (crashes on Wayland)
  };

  # Steam gaming platform — disabled for now (pulls the corefonts FOD, whose
  # upstream download currently hash-mismatches). Re-enable once resolved.
  # programs.steam.enable = true;

  # uinput access for Sunshine virtual input devices
  # hidraw access for user (HID devices like keyboards, mice, etc.)
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users"
  '';
  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;  # Creates uinput group and sets up permissions

  # Bluetooth KVM - relay keyboard/mouse to OnePlus Pad 3 via BLE HOGP
  # (needs the bt-kvm binary at the path below — build from ~/src/synMaybe)
  systemd.services.bt-kvm = {
    description = "Bluetooth KVM input relay (BLE HOGP)";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "/home/bluesign/src/synMaybe/bt-kvm -config /home/bluesign/src/synMaybe/config.toml";
      Restart = "on-failure";
      RestartSec = 3;
      Nice = -10;
      CPUSchedulingPolicy = "fifo";
      CPUSchedulingPriority = 50;
      IOSchedulingClass = "realtime";
    };
  };

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" "uinput" "video" ];
    packages = with pkgs; [ tree unityhub ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
