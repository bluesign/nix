{ config, lib, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 0;
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_number_position "right"
          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_default_text "#W"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_window_current_text "#W"
          set -g @catppuccin_status_modules_right "directory session"
          set -g @catppuccin_status_left_separator  " "
          set -g @catppuccin_status_right_separator ""
          set -g @catppuccin_status_fill "icon"
          set -g @catppuccin_status_connect_separator "no"
          set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -ag terminal-overrides ",alacritty:RGB"

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Set window notifications
      setw -g monitor-activity on
      set -g visual-activity off

      # Allow passthrough for images
      set -g allow-passthrough on

      # Focus events for vim autoread
      set -g focus-events on

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Alt + arrow keys to switch panes (without prefix)
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift + arrow to switch windows (without prefix)
      bind -n S-Left previous-window
      bind -n S-Right next-window

      # Resize panes with Ctrl + hjkl
      bind -r C-h resize-pane -L 5
      bind -r C-j resize-pane -D 5
      bind -r C-k resize-pane -U 5
      bind -r C-l resize-pane -R 5

      # Quick reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Vi copy mode improvements
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Don't exit copy mode after mouse selection
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-no-clear

      # Double click to select word
      bind -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word

      # Triple click to select line
      bind -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line

      # Status bar position
      set -g status-position top
    '';
  };
}
