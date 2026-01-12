# NixOS Recovery Partition Setup

This creates a minimal recovery system on a dedicated EFI partition that can bootstrap NixOS from any GitHub repository.

## Setup Instructions

### 1. Create a Recovery Partition

Create a small partition (2-4GB recommended) for the recovery system:

```bash
# Example using parted (adjust device name)
sudo parted /dev/nvme0n1

# Create a 4GB partition for recovery
(parted) mkpart recovery ext4 100GB 104GB
(parted) quit

# Format and label
sudo mkfs.ext4 -L RECOVERY /dev/nvme0n1pX
```

### 2. Update hardware-configuration.nix

Edit `hosts/recovery/hardware-configuration.nix` to match your system:

```bash
# Find your partition UUIDs
lsblk -f

# Update the file with correct UUIDs/labels
vim hosts/recovery/hardware-configuration.nix
```

### 3. Build and Install Recovery System

```bash
# Mount the recovery partition
sudo mkdir -p /mnt/recovery
sudo mount /dev/disk/by-label/RECOVERY /mnt/recovery
sudo mkdir -p /mnt/recovery/boot
sudo mount /dev/disk/by-label/EFI /mnt/recovery/boot

# Install the recovery system
sudo nixos-install --root /mnt/recovery --flake .#recovery

# Unmount
sudo umount /mnt/recovery/boot
sudo umount /mnt/recovery
```

### 4. Add Boot Entry

The recovery system will automatically appear in your systemd-boot menu.

If you want to add it manually:

```bash
# Create boot entry
cat << 'EOF' | sudo tee /boot/loader/entries/recovery.conf
title   NixOS Recovery
linux   /recovery/bzImage
initrd  /recovery/initrd
options root=LABEL=RECOVERY rw
EOF
```

## Usage

1. Reboot and select "NixOS Recovery" from boot menu
2. Login as `root` (password: `recovery`)
3. Run `nixos-bootstrap`
4. Follow the prompts:
   - Select WiFi or Wired connection
   - Enter your GitHub config URL
   - Select target hostname
   - Choose install or switch

## Features

- **Interactive network setup**: WiFi and wired support via NetworkManager
- **GitHub clone**: Clone any NixOS flake from GitHub
- **Host selection**: Auto-detects available hosts from flake.nix
- **Fresh install or update**: Supports both `nixos-install` and `nixos-rebuild switch`
- **SSH enabled**: Remote recovery possible (root password: `recovery`)

## Security Notes

- Change the default root password in `default.nix` before deploying
- SSH with root login is enabled for recovery convenience
- Consider disabling SSH or using keys for production use

## Manual Commands

If the bootstrap script doesn't work, use these commands manually:

```bash
# Setup WiFi
nmtui

# Or via CLI
nmcli device wifi list
nmcli device wifi connect "SSID" password "password"

# Clone config
git clone https://github.com/user/nixos-config /tmp/config

# Rebuild
nixos-rebuild switch --flake /tmp/config#hostname
```
