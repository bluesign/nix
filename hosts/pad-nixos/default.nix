# Host: pad-nixos — Native NixOS on OnePlus Pad 3 (SM8750 / Adreno 830)
# Minimal config: console + SSH, vendor kernel modules loaded at boot
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "pad-nixos";

  # No bootloader — we manually create boot.img with mkbootimg
  boot.loader.grub.enable = false;

  # The Android GKI kernel (6.6.89) has UFS/SCSI/ext4 built-in
  # No modules needed in initrd for basic boot
  boot.initrd.availableKernelModules = lib.mkForce [];
  boot.initrd.kernelModules = lib.mkForce [];
  boot.initrd.includeDefaultModules = false;
  boot.initrd.supportedFilesystems = lib.mkForce [ "ext4" ];
  boot.kernelModules = [];

  # Console + boot params
  boot.kernelParams = [
    "console=tty0"
    "fw_devlink=permissive"
  ];

  # Getty on tty0 for display console
  systemd.services."getty@tty0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
  };

  # Load vendor modules from vendor ramdisk before mounting root
  # The vendor_boot ramdisk provides 506 .ko modules at /lib/modules/
  # including critical ones: qcom_wdt_core, gh_virt_wdt, UFS PHY, SMMU, clocks
  boot.initrd.preDeviceCommands = ''
    if [ -f /lib/modules/modules.load ]; then
      echo "Loading vendor ramdisk modules..."
      while IFS= read -r ko; do
        if [ -f "/lib/modules/$ko" ]; then
          insmod "/lib/modules/$ko" 2>/dev/null || true
        fi
      done < /lib/modules/modules.load
      echo "Vendor modules loaded."
    fi
  '';

  # Vendor kernel modules (451 .ko files from /vendor/lib/modules/)
  # Copied to /opt/vendor/modules/ on the rootfs, loaded at boot
  systemd.services.vendor-modules = {
    description = "Load vendor kernel modules";
    wantedBy = [ "multi-user.target" ];
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "load-vendor-modules" ''
        MODULE_DIR=/opt/vendor/modules
        FIRMWARE_DIR=/opt/vendor/firmware
        LOAD_ORDER=$MODULE_DIR/modules.load
        # Set firmware search path
        for p in /sys/module/firmware_class/parameters/path; do
          [ -w "$p" ] && echo "$FIRMWARE_DIR" > "$p" 2>/dev/null || true
        done
        # Symlink firmware to /lib/firmware so kernel can find it
        mkdir -p /lib/firmware
        for f in "$FIRMWARE_DIR"/*; do
          [ -e "$f" ] && ln -sf "$f" /lib/firmware/ 2>/dev/null || true
        done
        if [ -d "$MODULE_DIR" ]; then
          if [ -f "$LOAD_ORDER" ]; then
            # Load in vendor-specified dependency order
            while IFS= read -r ko; do
              [ -f "$MODULE_DIR/$ko" ] && insmod "$MODULE_DIR/$ko" 2>/dev/null || true
            done < "$LOAD_ORDER"
          else
            for ko in "$MODULE_DIR"/*.ko; do
              insmod "$ko" 2>/dev/null || true
            done
          fi
        fi
      '';
    };
  };

  # Networking — eth0 for VM
  networking = {
    useDHCP = false;
    interfaces.eth0 = {
      ipv4.addresses = [{ address = "192.168.8.3"; prefixLength = 24; }];
    };
    defaultGateway = "192.168.8.1";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    firewall.enable = false;
  };

  # SSH server
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    iw             # WiFi management
    wpa_supplicant # WiFi client
    usbutils       # lsusb
    pciutils       # lspci
    kmod           # modprobe/insmod/lsmod
  ];

  # User
  users.users.root.initialPassword = "nixos";

  # Shell
  programs.zsh.enable = true;

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}
