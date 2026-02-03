# Hardware configuration for gunyah-nixos (crosvm/Gunyah VM)
{ config, lib, pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  # virtiofs root filesystem (tag "rootfs" provided by crosvm --shared-dir)
  fileSystems."/" = {
    device = "rootfs";
    fsType = "virtiofs";
  };

  # No swap in VM
  swapDevices = [];
}
