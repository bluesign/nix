{ config, pkgs, ... }:

let 
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    qtile = "qtile";
    nvim = "nvim";
    rofi = "rofi";
    niri = "niri";
    fuzzel = "fuzzel";
  };
in

{

imports = [
	./alacritty.nix
];


  programs.home-manager.enable = true;

 	home.username = "bluesign";
	home.homeDirectory = "/home/bluesign";
	programs.git.enable = true;
	home.stateVersion = "25.11";

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };
 

	home.packages = with pkgs; [
		#desktop 
	 	fuzzel
  	bluetuith
		
		#dev
		cargo
		just
		unzip

		google-cloud-sdk
		go
		golangci-lint

		gh
		neovim
		ripgrep
		gcc	
		nodejs
		nil
		nixpkgs-fmt
		#utils
		google-chrome
		discord-ptb
	];
}
