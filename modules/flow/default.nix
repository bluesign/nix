# Flow blockchain development module
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/flow-cli/default.nix { })
    pkgs.tree-sitter-cadence
  ];

  # Set path for Neovim treesitter integration
  environment.variables.TREE_SITTER_CADENCE_PATH = "${pkgs.tree-sitter-cadence}";
}
