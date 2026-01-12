# Minimal recovery system for EFI partition
# Boots to a shell with network setup and GitHub bootstrap capabilities
{ config, lib, pkgs, ... }:

let
  bootstrap-script = pkgs.writeShellScriptBin "nixos-bootstrap" ''
    #!/usr/bin/env bash
    set -e

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    echo -e "''${BLUE}====================================''${NC}"
    echo -e "''${BLUE}   NixOS Bootstrap from GitHub      ''${NC}"
    echo -e "''${BLUE}====================================''${NC}"
    echo ""

    # Step 1: Check/Setup Network
    setup_network() {
        echo -e "''${YELLOW}[1/4] Checking network connectivity...''${NC}"

        if ping -c 1 github.com &> /dev/null; then
            echo -e "''${GREEN}Network is already connected!''${NC}"
            return 0
        fi

        echo -e "''${YELLOW}No network connection detected.''${NC}"
        echo ""
        echo "Select connection type:"
        echo "  1) Wired (Ethernet)"
        echo "  2) WiFi"
        echo "  3) Skip (already configured)"
        read -p "Choice [1-3]: " net_choice

        case $net_choice in
            1)
                echo -e "''${YELLOW}Enabling NetworkManager for wired connection...''${NC}"
                sudo systemctl start NetworkManager
                sudo nmcli device connect $(nmcli device | grep ethernet | awk '{print $1}' | head -1) 2>/dev/null || true
                sleep 3
                ;;
            2)
                echo -e "''${YELLOW}Scanning for WiFi networks...''${NC}"
                sudo systemctl start NetworkManager
                sleep 2
                nmcli device wifi rescan 2>/dev/null || true
                sleep 2
                echo ""
                echo "Available networks:"
                nmcli device wifi list
                echo ""
                read -p "Enter WiFi SSID: " wifi_ssid
                read -sp "Enter WiFi password: " wifi_pass
                echo ""
                echo -e "''${YELLOW}Connecting to $wifi_ssid...''${NC}"
                sudo nmcli device wifi connect "$wifi_ssid" password "$wifi_pass"
                sleep 3
                ;;
            3)
                echo "Skipping network setup..."
                ;;
            *)
                echo -e "''${RED}Invalid choice''${NC}"
                return 1
                ;;
        esac

        # Verify connection
        if ping -c 1 github.com &> /dev/null; then
            echo -e "''${GREEN}Network connected successfully!''${NC}"
        else
            echo -e "''${RED}Failed to connect to network. Please check your settings.''${NC}"
            return 1
        fi
    }

    # Step 2: Get GitHub URL
    get_github_url() {
        echo ""
        echo -e "''${YELLOW}[2/4] GitHub Repository Setup''${NC}"
        echo ""
        echo "Enter the GitHub URL for your NixOS configuration."
        echo "Examples:"
        echo "  - https://github.com/username/nixos-config"
        echo "  - git@github.com:username/nixos-config.git"
        echo ""
        read -p "GitHub URL: " GITHUB_URL

        if [ -z "$GITHUB_URL" ]; then
            echo -e "''${RED}No URL provided!''${NC}"
            return 1
        fi

        export GITHUB_URL
        echo -e "''${GREEN}Repository: $GITHUB_URL''${NC}"
    }

    # Step 3: Clone repository
    clone_repo() {
        echo ""
        echo -e "''${YELLOW}[3/4] Cloning repository...''${NC}"

        CLONE_DIR="/mnt/etc/nixos"

        # Check if /mnt is mounted (for fresh installs)
        if ! mountpoint -q /mnt 2>/dev/null; then
            echo -e "''${YELLOW}/mnt is not mounted. Using /tmp for clone.''${NC}"
            echo "Make sure to mount your target filesystem to /mnt first for fresh installs."
            CLONE_DIR="/tmp/nixos-config"
        fi

        if [ -d "$CLONE_DIR" ] && [ "$(ls -A $CLONE_DIR 2>/dev/null)" ]; then
            echo -e "''${YELLOW}Directory $CLONE_DIR already exists.''${NC}"
            read -p "Remove and re-clone? [y/N]: " remove_choice
            if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
                sudo rm -rf "$CLONE_DIR"
            else
                echo "Using existing directory."
                export CLONE_DIR
                return 0
            fi
        fi

        sudo mkdir -p "$(dirname $CLONE_DIR)"
        sudo git clone "$GITHUB_URL" "$CLONE_DIR"

        if [ $? -eq 0 ]; then
            echo -e "''${GREEN}Repository cloned to $CLONE_DIR''${NC}"
            export CLONE_DIR
        else
            echo -e "''${RED}Failed to clone repository!''${NC}"
            return 1
        fi
    }

    # Step 4: Select host and rebuild
    rebuild_system() {
        echo ""
        echo -e "''${YELLOW}[4/4] NixOS Rebuild''${NC}"
        echo ""

        # List available hosts from flake
        echo "Available hosts in flake:"
        cd "$CLONE_DIR"
        nix flake show --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.nixosConfigurations | keys[]' 2>/dev/null || \
            echo "  (Could not auto-detect hosts - check flake.nix manually)"
        echo ""

        read -p "Enter hostname to build: " TARGET_HOST

        if [ -z "$TARGET_HOST" ]; then
            echo -e "''${RED}No hostname provided!''${NC}"
            return 1
        fi

        echo ""
        echo "Select operation:"
        echo "  1) nixos-rebuild switch (update running system)"
        echo "  2) nixos-install (fresh installation to /mnt)"
        read -p "Choice [1-2]: " rebuild_choice

        case $rebuild_choice in
            1)
                echo -e "''${YELLOW}Running: nixos-rebuild switch --flake $CLONE_DIR#$TARGET_HOST''${NC}"
                sudo nixos-rebuild switch --flake "$CLONE_DIR#$TARGET_HOST"
                ;;
            2)
                if ! mountpoint -q /mnt; then
                    echo -e "''${RED}/mnt is not mounted! Please mount your target filesystem first.''${NC}"
                    echo "Example:"
                    echo "  mount /dev/nvme0n1p2 /mnt"
                    echo "  mkdir -p /mnt/boot"
                    echo "  mount /dev/nvme0n1p1 /mnt/boot"
                    return 1
                fi
                echo -e "''${YELLOW}Running: nixos-install --flake $CLONE_DIR#$TARGET_HOST''${NC}"
                sudo nixos-install --flake "$CLONE_DIR#$TARGET_HOST"
                ;;
            *)
                echo -e "''${RED}Invalid choice''${NC}"
                return 1
                ;;
        esac

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "''${GREEN}====================================''${NC}"
            echo -e "''${GREEN}   NixOS Bootstrap Complete!        ''${NC}"
            echo -e "''${GREEN}====================================''${NC}"
            echo ""
            echo "You can now reboot into your new system."
        else
            echo -e "''${RED}Build failed! Check the errors above.''${NC}"
            return 1
        fi
    }

    # Main execution
    setup_network || exit 1
    get_github_url || exit 1
    clone_repo || exit 1
    rebuild_system || exit 1
  '';
in
{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader for EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # Hostname
  networking.hostName = "recovery";

  # Enable flakes
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  # Networking - enable both wired and wireless
  networking.networkmanager.enable = true;
  networking.wireless.enable = false; # Conflicts with NetworkManager

  # Localization
  time.timeZone = "Europe/Amsterdam";

  # Minimal system packages for recovery
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    curl
    git

    # Network tools
    networkmanager
    wpa_supplicant
    iw
    wirelesstools

    # Disk tools
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    btrfs-progs
    ntfs3g

    # System tools
    htop
    pciutils
    usbutils
    lshw

    # JSON parsing for flake inspection
    jq

    # The bootstrap script
    bootstrap-script
  ];

  # Auto-login to root for recovery
  services.getty.autologinUser = "root";

  # Display welcome message on login
  environment.etc."motd".text = ''

    ╔═══════════════════════════════════════════════════════════════╗
    ║              NixOS Recovery / Bootstrap System                ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║                                                               ║
    ║  Run 'nixos-bootstrap' to:                                    ║
    ║    1. Setup network (WiFi or Wired)                           ║
    ║    2. Enter GitHub repository URL                             ║
    ║    3. Clone and rebuild NixOS                                 ║
    ║                                                               ║
    ║  Manual commands available:                                   ║
    ║    nmtui          - Network Manager TUI                       ║
    ║    nmcli          - Network Manager CLI                       ║
    ║    lsblk          - List block devices                        ║
    ║    parted         - Partition editor                          ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝

  '';

  # Enable SSH for remote recovery
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set a simple root password for recovery (change this!)
  users.users.root.initialPassword = "recovery";

  # System state version
  system.stateVersion = "25.11";
}
