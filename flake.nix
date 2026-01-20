{
  description = "bluesign's nixos";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";

    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    cosmic-session.url = "github:bluelinden/cosmic-session";
    cosmic-ext-extra-sessions = {
      url = "github:KiaraGrouwstra/cosmic-ext-extra-sessions";
      flake = false;
    };
    claude-code.url = "github:sadjow/claude-code-nix";
    tree-sitter-cadence.url = "github:bluesign/tree-sitter-cadence";
    niri.url = "github:sodiboo/niri-flake";
    nfsm.url = "github:gvolpe/nfsm";
    niri-float-sticky.url = "github:probeldev/niri-float-sticky";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, claude-code, tree-sitter-cadence, niri, nfsm, dms, ... }@inputs:
    let
      # Helper function to create a host configuration
      mkHost = { hostname, system ? "x86_64-linux", users ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${hostname}
            {
              nixpkgs.overlays = [
                claude-code.overlays.default
                tree-sitter-cadence.overlays.default
              ];
              environment.systemPackages = [ claude-code ];
            }
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                sharedModules = [ niri.homeModules.niri nfsm.homeModules.default dms.homeModules.dankMaterialShell.default ];
                users = builtins.listToAttrs (map (user: {
                  name = user;
                  value = import ./users/${user};
                }) users);
                backupFileExtension = "hm-backup";
              };
            }
          ];
        };
    in {
      nixosConfigurations = {
        # Add new hosts here:
        # hostname = mkHost { hostname = "hostname"; users = [ "user1" "user2" ]; };

        bluebook = mkHost {
          hostname = "bluebook";
          users = [ "bluesign" ];
        };

        blueminix = mkHost {
          hostname = "blueminix";
          users = [ "bluesign" ];
        };

        # Minimal recovery system - no home-manager needed
        recovery = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/recovery ];
        };
      };
    };
}
