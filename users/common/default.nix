# Common user configuration - applied to all users
{ config, lib, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Dev tools
    cargo
    just
    unzip
    ripgrep
    gcc
    nodejs

    # Utils
    gh
    xdg-utils
  ];

  programs.git.enable = true;
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      open = "xdg-open";
      icat = "kitty +kitten icat";
      img = "chafa -f kitty";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    shellAliases = {
      open = "xdg-open";
      icat = "kitty +kitten icat";
      img = "chafa -f kitty";
      vim = "nvim";
      y = "yazi";
      claude = "claude --dangerously-skip-permissions";
    };
    history = {
      size = 100000;
      save = 100000;
      share = true;          # Share history between sessions live
      ignoreDups = true;     # Don't store duplicate commands
      ignoreSpace = true;    # Don't store commands starting with space
      extended = true;       # Save timestamps
    };
    initExtra = ''
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      # Accept autosuggestion with Ctrl+Space
      bindkey '^ ' autosuggest-accept
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;  # Binds Ctrl+R to fzf history search
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "z" ];  # Use 'z' and 'zi' commands
  };
}
