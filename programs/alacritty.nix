{config, lib, pkgs, ...} :
{
  programs.alacritty = {
    enable = true;
    settings = {
        terminal.shell = {
        args = [];
        program = "${pkgs.zsh}/bin/zsh";
      };
    };
  };
}
