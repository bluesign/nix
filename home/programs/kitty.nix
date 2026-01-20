{ config, lib, pkgs, ... }: {
  home.sessionVariables = {
    KITTY_INSTALLATION_DIR = "${pkgs.kitty}/lib/kitty";
  };

  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      # Font
      font_size = 11;

      # Graphics
      allow_remote_control = "yes";

      # Scrollback
      scrollback_lines = 10000;

      # Window
      window_padding_width = 4;
      confirm_os_window_close = 0;
      background_opacity = "0.9";

      # URLs
      url_style = "curly";
      open_url_with = "default";

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = 0;
    };

    keybindings = {
      "ctrl+shift+equal" = "change_font_size all +1.0";
      "ctrl+shift+plus" = "change_font_size all +1.0";
      "ctrl+shift+minus" = "change_font_size all -1.0";
      "ctrl+shift+backspace" = "change_font_size all 0";
    };
  };
}
