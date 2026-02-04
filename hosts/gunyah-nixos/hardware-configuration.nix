# Hardware configuration for gunyah-nixos (crosvm/Gunyah VM)
{ config, lib, pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  # ext4 root filesystem on virtio block device
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };

  # No swap in VM
  swapDevices = [];
}
