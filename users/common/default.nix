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
    system-config-printer
    mullvad-vpn
    mitmproxy
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
      scrcpy = "scrcpy --render-driver=opengl --turn-screen-off --stay-awake --window-width=420 --window-height=904";
      pixel = "scrcpy --render-driver=opengl --turn-screen-off --stay-awake --window-width=420 --window-height=904";
    };
    history = {
      size = 100000;
      save = 100000;
      share = true;          # Share history between sessions live
      ignoreDups = true;     # Don't store duplicate commands
      ignoreSpace = true;    # Don't store commands starting with space
      extended = true;       # Save timestamps
    };
    initContent = ''
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      # Accept autosuggestion with Ctrl+Space
      bindkey '^ ' autosuggest-accept

      # Load API keys from pass if available
      if command -v pass &> /dev/null && [ -d "$HOME/.password-store" ]; then
        export OPENAI_API_KEY="$(pass show api/openai 2>/dev/null)"
      fi

      # Pixel file transfer functions
      topixel() { adb push "$@" /sdcard/Download/; }
      frompixel() { adb pull "/sdcard/Download/$1" .; }
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
