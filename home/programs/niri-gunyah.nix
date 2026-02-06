# Niri config for gunyah-nixos VM
# Based on blueminix niri.nix but with Alt as primary modifier (avoids host Super conflict)
# Removed: dms, swayosd, nfsm, wl-kbptr, niri-float-sticky, google-chrome, keyboard backlight
{ config, lib, pkgs, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;

    settings = {
      outputs = {
        "Virtual-1" = {
          scale = 2.0;
          mode = {
            width = 1696;
            height = 1200;
          };
        };
      };

      input = {
        keyboard = {
          xkb = {};
        };
        mouse = {};
      };

      layout = {
        gaps = 10;
        center-focused-column = "never";

        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];

        default-column-width = { proportion = 0.5; };

        focus-ring = {
          width = 4;
          active.color = "#7fc8ff";
          inactive.color = "#505050";
        };

        border = {
          enable = false;
        };

        shadow = {
          enable = false;
        };

        struts = {};
      };

      spawn-at-startup = [
        { command = [ "systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" "DISPLAY" ]; }
        { command = [ "systemctl" "--user" "start" "xdg-desktop-portal-gnome.service" ]; }
      ];

      prefer-no-csd = false;

      hotkey-overlay = {};

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      animations = {};

      window-rules = [
        {
          matches = [{ app-id = "firefox$"; title = "^Picture-in-Picture$"; }];
          open-floating = true;
        }
        {
          matches = [{ app-id = "^mpv$"; }];
          open-floating = true;
        }
        {
          matches = [{ is-focused = true; }];
          opacity = 1.0;
        }
        {
          matches = [{ is-focused = false; }];
          opacity = 0.80;
        }
        {
          matches = [{ is-floating = true; }];
          opacity = 1.0;
        }
      ];

      binds = {
        # Show hotkey overlay
        "Alt+Shift+Slash".action.show-hotkey-overlay = [];

        # Applications
        "Alt+T" = {
          action.spawn = "foot";
          hotkey-overlay.title = "Open Terminal: foot";
        };
        "Alt+D" = {
          action.spawn = "fuzzel";
          hotkey-overlay.title = "Run Application: fuzzel";
        };
        "Alt+I" = {
          action.spawn = "alacritty";
          hotkey-overlay.title = "Open Terminal: alacritty";
        };
        "Alt+U" = {
          action.spawn = [ "google-chrome-stable" "--no-sandbox" "--ozone-platform=wayland" ];
          hotkey-overlay.title = "Open Browser: Chrome";
        };

        # Media controls
        "XF86AudioPlay" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl play-pause" ];
        };
        "XF86AudioStop" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl stop" ];
        };
        "XF86AudioPrev" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl previous" ];
        };
        "XF86AudioNext" = {
          allow-when-locked = true;
          action.spawn = [ "sh" "-c" "playerctl next" ];
        };

        # Overview
        "Alt+O" = {
          repeat = false;
          action.toggle-overview = [];
        };

        # Close window
        "Alt+Q" = {
          repeat = false;
          action.close-window = [];
        };

        # Focus navigation (arrow keys)
        "Alt+Left".action.focus-column-left = [];
        "Alt+Down".action.focus-window-down = [];
        "Alt+Up".action.focus-window-up = [];
        "Alt+Right".action.focus-column-right = [];

        # Focus navigation (vim keys)
        "Alt+H".action.focus-column-left = [];
        "Alt+J".action.focus-window-or-workspace-down = [];
        "Alt+K".action.focus-window-or-workspace-up = [];
        "Alt+L".action.focus-column-right = [];

        # Move windows (arrow keys)
        "Alt+Ctrl+Left".action.move-column-left = [];
        "Alt+Ctrl+Down".action.move-window-down = [];
        "Alt+Ctrl+Up".action.move-window-up = [];
        "Alt+Ctrl+Right".action.move-column-right = [];

        # Move windows (vim keys)
        "Alt+Ctrl+H".action.move-column-left = [];
        "Alt+Ctrl+J".action.move-window-down-or-to-workspace-down = [];
        "Alt+Ctrl+K".action.move-window-up-or-to-workspace-up = [];
        "Alt+Ctrl+L".action.move-column-right = [];

        # Column navigation
        "Alt+Home".action.focus-column-first = [];
        "Alt+End".action.focus-column-last = [];
        "Alt+Ctrl+Home".action.move-column-to-first = [];
        "Alt+Ctrl+End".action.move-column-to-last = [];

        # Monitor focus (arrow keys)
        "Alt+Shift+Left".action.focus-monitor-left = [];
        "Alt+Shift+Down".action.focus-monitor-down = [];
        "Alt+Shift+Up".action.focus-monitor-up = [];
        "Alt+Shift+Right".action.focus-monitor-right = [];

        # Monitor focus (vim keys)
        "Alt+Shift+H".action.focus-monitor-left = [];
        "Alt+Shift+J".action.focus-monitor-down = [];
        "Alt+Shift+K".action.focus-monitor-up = [];
        "Alt+Shift+L".action.focus-monitor-right = [];

        # Move to monitor (arrow keys)
        "Alt+Shift+Ctrl+Left".action.move-column-to-monitor-left = [];
        "Alt+Shift+Ctrl+Down".action.move-column-to-monitor-down = [];
        "Alt+Shift+Ctrl+Up".action.move-column-to-monitor-up = [];
        "Alt+Shift+Ctrl+Right".action.move-column-to-monitor-right = [];

        # Move to monitor (vim keys)
        "Alt+Shift+Ctrl+H".action.move-column-to-monitor-left = [];
        "Alt+Shift+Ctrl+J".action.move-column-to-monitor-down = [];
        "Alt+Shift+Ctrl+K".action.move-column-to-monitor-up = [];
        "Alt+Shift+Ctrl+L".action.move-column-to-monitor-right = [];

        # Workspace navigation
        "Alt+Page_Down".action.focus-workspace-down = [];
        "Alt+Page_Up".action.focus-workspace-up = [];
        "Alt+Ctrl+Page_Down".action.move-column-to-workspace-down = [];
        "Alt+Ctrl+Page_Up".action.move-column-to-workspace-up = [];

        # Move workspace
        "Alt+Shift+Page_Down".action.move-workspace-down = [];
        "Alt+Shift+Page_Up".action.move-workspace-up = [];

        # Mouse wheel workspace navigation
        "Alt+WheelScrollDown" = {
          cooldown-ms = 150;
          action.focus-workspace-down = [];
        };
        "Alt+WheelScrollUp" = {
          cooldown-ms = 150;
          action.focus-workspace-up = [];
        };
        "Alt+Ctrl+WheelScrollDown" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-down = [];
        };
        "Alt+Ctrl+WheelScrollUp" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-up = [];
        };

        # Mouse wheel column navigation
        "Alt+WheelScrollRight".action.focus-column-right = [];
        "Alt+WheelScrollLeft".action.focus-column-left = [];
        "Alt+Ctrl+WheelScrollRight".action.move-column-right = [];
        "Alt+Ctrl+WheelScrollLeft".action.move-column-left = [];

        # Shift + mouse wheel
        "Alt+Shift+WheelScrollDown".action.focus-column-right = [];
        "Alt+Shift+WheelScrollUp".action.focus-column-left = [];
        "Alt+Ctrl+Shift+WheelScrollDown".action.move-column-right = [];
        "Alt+Ctrl+Shift+WheelScrollUp".action.move-column-left = [];

        # Workspace by number
        "Alt+1".action.focus-workspace = 1;
        "Alt+2".action.focus-workspace = 2;
        "Alt+3".action.focus-workspace = 3;
        "Alt+4".action.focus-workspace = 4;
        "Alt+5".action.focus-workspace = 5;
        "Alt+6".action.focus-workspace = 6;
        "Alt+7".action.focus-workspace = 7;
        "Alt+8".action.focus-workspace = 8;
        "Alt+9".action.focus-workspace = 9;

        # Move to workspace by number
        "Alt+Ctrl+1".action.move-column-to-workspace = 1;
        "Alt+Ctrl+2".action.move-column-to-workspace = 2;
        "Alt+Ctrl+3".action.move-column-to-workspace = 3;
        "Alt+Ctrl+4".action.move-column-to-workspace = 4;
        "Alt+Ctrl+5".action.move-column-to-workspace = 5;
        "Alt+Ctrl+6".action.move-column-to-workspace = 6;
        "Alt+Ctrl+7".action.move-column-to-workspace = 7;
        "Alt+Ctrl+8".action.move-column-to-workspace = 8;
        "Alt+Ctrl+9".action.move-column-to-workspace = 9;

        # Column operations
        "Alt+BracketLeft".action.consume-or-expel-window-left = [];
        "Alt+BracketRight".action.consume-or-expel-window-right = [];
        "Alt+G".action.consume-or-expel-window-left = [];
        "Alt+Semicolon".action.consume-or-expel-window-right = [];
        "Alt+Comma".action.consume-window-into-column = [];
        "Alt+Period".action.expel-window-from-column = [];

        # Window sizing
        "Alt+R".action.switch-preset-column-width = [];
        "Alt+Shift+R".action.switch-preset-window-height = [];
        "Alt+Ctrl+R".action.reset-window-height = [];
        "Alt+F".action.fullscreen-window = [];
        "Alt+Shift+F".action.maximize-column = [];
        "Alt+Ctrl+F".action.expand-column-to-available-width = [];

        # Centering
        "Alt+C".action.center-column = [];
        "Alt+Ctrl+C".action.center-visible-columns = [];

        # Height adjustments
        "Alt+Shift+Minus".action.set-window-height = "-10%";
        "Alt+Shift+Equal".action.set-window-height = "+10%";

        # Floating
        "Alt+V".action.toggle-window-floating = [];
        "Alt+Shift+V".action.switch-focus-between-floating-and-tiling = [];

        # Tabbed mode
        "Alt+W".action.toggle-column-tabbed-display = [];

        # Screenshots (niri built-in)
        "Print".action.screenshot = [];
        "Ctrl+Print".action.screenshot-screen = [];
        "Alt+Print".action.screenshot-window = [];

        # Keyboard shortcuts inhibit toggle
        "Alt+Escape" = {
          allow-inhibiting = false;
          action.toggle-keyboard-shortcuts-inhibit = [];
        };

        # Quit
        "Alt+Shift+E".action.quit = [];
        "Ctrl+Alt+Delete".action.quit = [];

        # Toggle scale 1x/2x
        "Alt+S" = {
          action.spawn = [ "sh" "-c" "if wlr-randr | grep -q 'Scale: 2'; then wlr-randr --output Virtual-1 --scale 1; else wlr-randr --output Virtual-1 --scale 2; fi" ];
          hotkey-overlay.title = "Toggle Scale 1x/2x";
        };

        # Power off monitors
        "Alt+Shift+P".action.power-off-monitors = [];
      };

      debug = {
        render-drm-device = "/dev/dri/renderD128";
      };
    };
  };
}
