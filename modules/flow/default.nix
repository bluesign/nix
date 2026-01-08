# Flow blockchain development module
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/flow-cli/default.nix { })
  ];
}
