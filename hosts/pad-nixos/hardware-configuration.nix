# Hardware configuration for pad-nixos (native boot on OnePlus Pad 3 / SM8750)
{ config, lib, pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  # Root filesystem on dedicated nixos partition (sda16)
  fileSystems."/" = {
    device = "/dev/sda16";
    fsType = "ext4";
  };

  swapDevices = [];
}
