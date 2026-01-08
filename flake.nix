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

  };

  outputs = { self, nixpkgs, home-manager, claude-code, ... }: {

    nixosConfigurations = {
      bluebook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          { networking.hostName = "bluebook"; }
          ./cosmic-on-niri.nix
          ./configuration.nix
          {
            nixpkgs.overlays = [ claude-code.overlays.default ];
            environment.systemPackages = [ claude-code ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.bluesign = import ./home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };

    };
  };
}
