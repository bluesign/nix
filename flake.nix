{
	description = "bluesign's nixos";
	inputs = {
		nixpkgs.url = "nixpkgs/nixos-25.11";
		home-manager = {
			url = "github:nix-community/home-manager/release-25.11";
			inputs.nixpkgs.follows = "nixpkgs";		
		};

    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    cosmic-session.url = "github:bluelinden/cosmic-session";
    cosmic-ext-extra-sessions = {
      url = "github:KiaraGrouwstra/cosmic-ext-extra-sessions";
      flake = false;
    };
		xdg-desktop-portal-cosmic.url	= "github:pop-os/xdg-desktop-portal-cosmic";

  };	



	outputs = { self, nixpkgs, home-manager, ... }: {
		nixosConfigurations.bluebook = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				{networking.hostName = "bluebook"; }
				./configuration.nix
				./cosmic-on-niri.nix
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
		nixosConfigurations.blueminix = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				{networking.hostName = "blueminix"; }
				./configuration.nix
				./cosmic-on-niri.nix
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
}
