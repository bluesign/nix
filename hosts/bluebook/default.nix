# Host: bluebook
# To add a new host, copy this file to hosts/<hostname>/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/desktop
    ../../modules/flow
  ];

  networking.hostName = "bluebook";

  # Users enabled on this host
  users.users.bluesign = {
    isNormalUser = true;
    extraGroups = [ "wheel" "keyd" ];
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
