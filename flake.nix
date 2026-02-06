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
    claude-code.inputs.nixpkgs.follows = "nixpkgs";
    tree-sitter-cadence.url = "github:bluesign/tree-sitter-cadence";
    tree-sitter-cadence.inputs.nixpkgs.follows = "nixpkgs";
    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs";
    nfsm.url = "github:gvolpe/nfsm";
    nfsm.inputs.nixpkgs.follows = "nixpkgs";
    niri-float-sticky.url = "github:probeldev/niri-float-sticky";
    niri-float-sticky.inputs.nixpkgs.follows = "nixpkgs";
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
          specialArgs = { inherit inputs; };
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

        # Gunyah/crosvm VM — niri Wayland compositor
        gunyah-nixos = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/gunyah-nixos
            {
              nixpkgs.overlays = [
                (final: prev: {
                  mesa = prev.mesa.overrideAttrs (oldAttrs: {
                    patches = (oldAttrs.patches or []) ++ [
                      ./patches/mesa-gfxstream-robustness2.patch
                    ];
                  });
                })
              ];
            }
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                sharedModules = [ niri.homeModules.niri ];
                users.bluesign = import ./users/bluesign/gunyah.nix;
                backupFileExtension = "hm-backup";
              };
            }
          ];
        };

        # Minimal recovery system - no home-manager needed
        recovery = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/recovery ];
        };
      };
    };
}
