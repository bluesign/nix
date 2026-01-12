# Host: blueminix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/desktop
    ../../modules/flow
  ];

  networking.hostName = "blueminix";

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

  # Sunshine remote desktop server
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for Wayland capture
    openFirewall = true;
  };

  # uinput access for Sunshine virtual input devices
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';
  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;  # Creates uinput group and sets up permissions

  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" "uinput" ];  # uinput group for Sunshine
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
