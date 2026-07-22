# Host: blueminix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/desktop
    ../../modules/flow
    ../../modules/gamedev
  ];

  networking.hostName = "blueminix";

  # Enable aarch64 emulation for cross-building (gunyah-nixos VM)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # AMD Radeon 780M graphics - stability fixes for freezes
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"  # Enable all power management features
    "amdgpu.gpu_recovery=1"             # Enable GPU hang recovery
    "amdgpu.dc=1"                       # Enable Display Core
    "amdgpu.dcdebugmask=0x10"           # Reduce DC debug overhead
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For Steam/gaming
    extraPackages = with pkgs; [
      rocmPackages.clr.icd  # OpenCL support
    ];
  };

  # Thunderbolt/USB4 support
  services.hardware.bolt.enable = true;

  # Firmware updates (BIOS, devices)
  services.fwupd.enable = true;

  # SSD TRIM for NVMe health
  services.fstrim.enable = true;

  # WirePlumber config for EliteMini - HDMI audio to monitor as default
  services.pipewire.wireplumber.extraConfig."50-blueminix-audio" = {
    "monitor.alsa.rules" = [
      {
        # Radeon HDMI audio - set as default output
        matches = [{ "device.name" = "alsa_card.pci-0000_c4_00.1"; }];
        actions.update-props = {
          "priority.driver" = 2000;
          "priority.session" = 2000;
          # Enable HDMI stereo profile by default
          "device.profile" = "output:hdmi-stereo";
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

  # Sunshine remote desktop server - override common config
  services.sunshine.settings = {
    dd_resolution_option = lib.mkForce "disabled";  # Don't auto-change resolution (causes crashes on Wayland)
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

  # Bluetooth KVM - relay keyboard/mouse to OnePlus Pad 3 via BLE HOGP
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
        PENPOT_PUBLIC_URI = "http://blueminix:9001";
        PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
        PENPOT_DATABASE_USERNAME = "penpot";
        PENPOT_DATABASE_PASSWORD = "penpot";
        PENPOT_REDIS_URI = "redis://penpot-redis/0";
        # Storage config (2.11+ format)
        PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
        PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";
        # Deprecated but keep for backwards compat during transition
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
    extraGroups = [ "wheel" "keyd" "uinput" "video" "docker" ];  # uinput for Sunshine, video for webcam, docker for container management
    packages = with pkgs; [ tree unityhub ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
