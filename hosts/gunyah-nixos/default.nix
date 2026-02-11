# Host: gunyah-nixos — NixOS VM for Gunyah/crosvm on OnePlus 13
# Standalone lightweight VM config — does NOT import ../common or ../../modules/desktop
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "gunyah-nixos";

  # No bootloader — crosvm provides kernel directly
  boot.loader.grub.enable = false;

  # Custom Gunyah kernel has everything built-in, no modules needed in initrd
  boot.initrd.availableKernelModules = lib.mkForce [];
  boot.initrd.kernelModules = lib.mkForce [];
  boot.initrd.includeDefaultModules = false;
  boot.initrd.supportedFilesystems = lib.mkForce [ "ext4" ];
  boot.kernelModules = [];

  # Console for crosvm serial
  boot.kernelParams = [ "console=hvc0" ];

  # Swap file (4GB — needed for building large packages like quickshell)
  swapDevices = [{ device = "/swapfile"; size = 4096; }];

  # Static networking: .3 for NixOS, .2 for Debian, .1 for host
  networking = {
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.8.3";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.8.1";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    firewall.enable = false;
  };

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # Shell
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "z" "fzf" "sudo" "systemadmin" "vi-mode" ];
  };
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  # SSH server
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Niri Wayland compositor on virtio-gpu
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = let
        niri-run = pkgs.writeShellScript "niri-run" ''
          unset DISPLAY
          export LIBSEAT_BACKEND=seatd
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
            pkgs.xorg.libXcursor pkgs.xorg.libXi pkgs.xorg.libXrandr
            pkgs.xorg.libX11 pkgs.xorg.libXext pkgs.xorg.libXrender
            pkgs.xorg.libXfixes pkgs.xorg.libxcb pkgs.xorg.libXinerama
          ]}
          exec ${pkgs.niri}/bin/niri --session
        '';
      in "${niri-run}";
      user = "bluesign";
    };
  };

  # seatd for seat management
  services.seatd = {
    enable = true;
    group = "video";
  };

  # Terminal
  environment.variables.TERMINAL = "foot";

  # XDG portal for niri (uses GNOME portal)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # UPower for battery status (needed by DMS/quickshell)
  services.upower.enable = true;
  # Gunyah kernel lacks user namespaces — disable sandboxing in upower unit
  systemd.services.upower.serviceConfig = {
    PrivateUsers = lib.mkForce false;
    RestrictNamespaces = lib.mkForce false;
  };

  # Mesa for virtio-gpu (gfxstream Vulkan + Zink for GL)
  hardware.graphics.enable = true;

  # Venus Vulkan ICD for Vulkan passthrough; desktop GL uses virgl (stable)
  environment.variables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/virtio_icd.aarch64.json";
  };

  # udev rules: seat tags for input devices, DRM/input permissions, readahead
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", TAG+="seat"
    SUBSYSTEM=="input", KERNEL=="event*", MODE="0666"
    SUBSYSTEM=="drm", MODE="0666"
    SUBSYSTEM=="block", KERNEL=="vda", ATTR{queue/read_ahead_kb}="4096"
  '';

  # Ensure /run/user/1000 exists for XDG_RUNTIME_DIR
  systemd.tmpfiles.rules = [
    "d /run/user/1000 0700 bluesign users -"
  ];

  # Disable kernel keyboard autorepeat (crosvm X11 input has delayed key releases)
  systemd.services.disable-autorepeat = {
    description = "Disable kernel keyboard autorepeat for crosvm";
    after = [ "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-autorepeat" ''
        for dev in /dev/input/event*; do
          ${pkgs.perl}/bin/perl -e 'use POSIX; my $rep = pack("LL", 10000, 100); ioctl(STDIN, 0x40084503, $rep)' < "$dev" 2>/dev/null || true
        done
      '';
    };
  };

  # Required by home-manager xdg portal config (from niri/desktop modules in user profile)
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Chromium SUID sandbox (kernel lacks user namespaces)
  security.chromiumSuidSandbox.enable = true;

  # Sudo without password
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    fzf
    firefox
    chromium

    # Niri desktop
    niri
    xwayland-satellite
    foot              # terminal
    alacritty         # GPU-accelerated terminal
    xterm             # fallback terminal
    fuzzel            # app launcher
    grim              # screenshots
    slurp             # region select
    wl-clipboard      # clipboard
    wlr-randr         # display management
    playerctl         # media control
    brightnessctl     # brightness control
    swaylock          # screen locker
    swaybg            # wallpaper

    # x86_64 emulation
    fex               # FEX-Emu: run x86_64 binaries on aarch64

    # GPU/display tools
    mesa-demos        # glxinfo/glxgears
    vulkan-tools
    glmark2
    evtest
    wev

    # X11 libs for niri runtime
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXfixes
    xorg.libxcb
    xorg.libXinerama

    # VNC remote desktop
    novnc
    python3Packages.websockify

    # Put.io TUI client
    (pkgs.callPackage ../../pkgs/putio { })
  ];

  # User
  users.users.root.initialPassword = "nixos";

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  # Fonts
  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting = {
      enable = true;
      style = "full";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };

  # --- LAN proxyarp: secondary IP from kernel cmdline ---
  # Start script passes vm_lan_ip=x.x.x.x vm_lan_gw=x.x.x.x vm_lan_prefix=24
  systemd.services.vm-lan-ip = {
    description = "Configure LAN IP from kernel cmdline (proxyarp)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "vm-lan-ip" ''
        CMDLINE=$(cat /proc/cmdline)

        VM_LAN_IP=""
        VM_LAN_GW=""
        VM_LAN_PREFIX="24"
        for param in $CMDLINE; do
          case "$param" in
            vm_lan_ip=*) VM_LAN_IP="''${param#vm_lan_ip=}" ;;
            vm_lan_gw=*) VM_LAN_GW="''${param#vm_lan_gw=}" ;;
            vm_lan_prefix=*) VM_LAN_PREFIX="''${param#vm_lan_prefix=}" ;;
          esac
        done

        if [ -z "$VM_LAN_IP" ] || [ -z "$VM_LAN_GW" ]; then
          echo "No vm_lan_ip or vm_lan_gw in kernel cmdline, skipping"
          exit 0
        fi

        echo "Adding LAN IP $VM_LAN_IP/$VM_LAN_PREFIX via gateway $VM_LAN_GW"
        ${pkgs.iproute2}/bin/ip addr add "$VM_LAN_IP/$VM_LAN_PREFIX" dev eth0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip route add default via "$VM_LAN_GW" dev eth0 src "$VM_LAN_IP" metric 50 2>/dev/null || true
        echo "LAN IP configured"
      '';
    };
  };

  # --- Performance tunings for virtio VM ---

  boot.kernel.sysctl = {
    # Low swappiness — prefer keeping pages in RAM over swapping to slow virtio-blk
    "vm.swappiness" = 10;
    # Reduce vfs cache pressure to keep dentries/inodes cached
    "vm.vfs_cache_pressure" = 50;
    # Dirty page tuning — flush sooner to avoid big I/O stalls
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  system.stateVersion = "25.11";
}
