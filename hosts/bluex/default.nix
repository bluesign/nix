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

  # Steam gaming platform
  programs.steam.enable = true;

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

  # Docker for containerized services (Penpot, etc.)
  virtualisation.docker.enable = true;

  # Penpot (self-hosted design tool)
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    penpot-postgres = {
      image = "postgres:15";
      environment = {
        POSTGRES_DB = "penpot";
        POSTGRES_USER = "penpot";
        POSTGRES_PASSWORD = "penpot";
      };
      volumes = [ "penpot-postgres:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=penpot" ];
    };

    penpot-redis = {
      image = "redis:7";
      extraOptions = [ "--network=penpot" ];
    };

    penpot-backend = {
      image = "penpotapp/backend:latest";
      dependsOn = [ "penpot-postgres" "penpot-redis" ];
      environment = {
        PENPOT_FLAGS = "enable-registration enable-login-with-password disable-email-verification enable-smtp enable-prepl-server disable-secure-session-cookies enable-access-tokens";
        PENPOT_PUBLIC_URI = "http://bluex:9001";
        PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
        PENPOT_DATABASE_USERNAME = "penpot";
        PENPOT_DATABASE_PASSWORD = "penpot";
        PENPOT_REDIS_URI = "redis://penpot-redis/0";
        PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
        PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";
        PENPOT_ASSETS_STORAGE_BACKEND = "assets-fs";
        PENPOT_STORAGE_ASSETS_FS_DIRECTORY = "/opt/data/assets";
        PENPOT_TELEMETRY_ENABLED = "false";
        PENPOT_SMTP_ENABLED = "false";
        PENPOT_SECRET_KEY = "f939a3befa456eac9d50c22787fa90b84a6bf90332004221117d4879d81122f3";
      };
      volumes = [ "penpot-assets:/opt/data/assets" ];
      extraOptions = [ "--network=penpot" ];
    };

    penpot-frontend = {
      image = "penpotapp/frontend:latest";
      dependsOn = [ "penpot-backend" "penpot-exporter" ];
      ports = [ "9001:8080" ];
      environment = {
        PENPOT_FLAGS = "enable-registration enable-login-with-password disable-email-verification";
      };
      volumes = [ "penpot-assets:/opt/data/assets" ];
      extraOptions = [ "--network=penpot" ];
    };

    penpot-exporter = {
      image = "penpotapp/exporter:latest";
      dependsOn = [ "penpot-redis" ];
      environment = {
        PENPOT_PUBLIC_URI = "http://penpot-frontend:8080";
        PENPOT_REDIS_URI = "redis://penpot-redis/0";
        PENPOT_SECRET_KEY = "f939a3befa456eac9d50c22787fa90b84a6bf90332004221117d4879d81122f3";
      };
      extraOptions = [ "--network=penpot" ];
    };
  };

  # Create penpot Docker network
  systemd.services.docker-penpot-network = {
    description = "Create Docker network for Penpot";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect penpot >/dev/null 2>&1 || ${pkgs.docker}/bin/docker network create penpot
    '';
  };

  # Ensure containers start after network is created
  systemd.services.docker-penpot-postgres.after = [ "docker-penpot-network.service" ];
  systemd.services.docker-penpot-redis.after = [ "docker-penpot-network.service" ];
  systemd.services.docker-penpot-backend.after = [ "docker-penpot-network.service" ];
  systemd.services.docker-penpot-frontend.after = [ "docker-penpot-network.service" ];
  systemd.services.docker-penpot-exporter.after = [ "docker-penpot-network.service" ];

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" "uinput" "video" "docker" ];
    packages = with pkgs; [ tree unityhub ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
