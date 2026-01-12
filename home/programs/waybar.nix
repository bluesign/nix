{ config, lib, pkgs, ... }:

let
  # Audio output switcher script
  audioSwitcher = pkgs.writeShellScriptBin "audio-switcher" ''
    # Get list of audio sinks (excluding Dummy Output)
    get_sinks() {
      ${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
        sed -n '/^Audio/,/^Video/p' | \
        grep -E '^\s+[│├└]?\s*[0-9]+\.' | \
        grep -i 'sink\|stereo\|hdmi\|speaker\|headphone\|clip\|bluetooth' | \
        grep -v 'Dummy' | \
        sed 's/^[│├└ ]*//; s/\[vol:.*//; s/ *$//'
    }

    # Get current default sink name
    get_current() {
      local current_id=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
        sed -n '/Sinks:/,/Sources:/p' | \
        grep '^\s*[│├└]\?\s*\*' | \
        sed 's/^[^0-9]*\([0-9]*\).*/\1/' | head -1)

      if [ -n "$current_id" ]; then
        ${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
          sed -n '/Sinks:/,/Sources:/p' | \
          grep "^\s*[│├└]\?\s*\*\?\s*$current_id\." | \
          sed 's/^[^.]*\. *//; s/\[vol:.*//' | \
          sed 's/ *$//' | head -1
      fi
    }

    # Get short name for display
    get_short_name() {
      local name="$1"
      if echo "$name" | grep -qi 'hdmi'; then
        echo "HDMI"
      elif echo "$name" | grep -qi 'clip\|jbl'; then
        echo "BT"
      elif echo "$name" | grep -qi 'bluetooth\|bluez'; then
        echo "BT"
      elif echo "$name" | grep -qi 'headphone'; then
        echo "HP"
      elif echo "$name" | grep -qi 'analog'; then
        echo "AUX"
      else
        echo "$name" | cut -c1-8
      fi
    }

    case "$1" in
      --status)
        current=$(get_current)
        if [ -n "$current" ]; then
          short=$(get_short_name "$current")
          echo "{\"text\": \"$short\", \"tooltip\": \"$current\", \"class\": \"audio-output\"}"
        else
          echo "{\"text\": \"--\", \"tooltip\": \"No audio output\", \"class\": \"no-audio\"}"
        fi
        ;;
      --switch)
        # Get all sink IDs
        sink_ids=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
          sed -n '/Sinks:/,/Sources:/p' | \
          grep -E '^\s*[│├└]?\s*\*?\s*[0-9]+\.' | \
          grep -v 'Dummy' | \
          sed 's/^[^0-9]*\([0-9]*\).*/\1/')

        # Get current default sink ID
        current_id=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
          sed -n '/Sinks:/,/Sources:/p' | \
          grep '^\s*[│├└]\?\s*\*' | \
          sed 's/^[^0-9]*\([0-9]*\).*/\1/' | head -1)

        # Convert to array
        ids=($sink_ids)
        count=''${#ids[@]}

        if [ "$count" -lt 2 ]; then
          ${pkgs.libnotify}/bin/notify-send "Audio" "Only one output available"
          exit 0
        fi

        # Find current index and switch to next
        next_id=""
        for i in "''${!ids[@]}"; do
          if [ "''${ids[$i]}" = "$current_id" ]; then
            next_idx=$(( (i + 1) % count ))
            next_id="''${ids[$next_idx]}"
            break
          fi
        done

        # If current not found, use first
        if [ -z "$next_id" ]; then
          next_id="''${ids[0]}"
        fi

        # Switch to next sink
        ${pkgs.wireplumber}/bin/wpctl set-default "$next_id"

        # Get new sink name and notify
        new_name=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
          sed -n '/Sinks:/,/Sources:/p' | \
          grep "^\s*[│├└]\?\s*\*\?\s*$next_id\." | \
          sed 's/^[^.]*\. *//; s/\[vol:.*//' | head -1)
        ${pkgs.libnotify}/bin/notify-send "Audio Output" "$new_name"
        ;;
      --menu)
        # Show menu with all sinks using fuzzel
        sink_lines=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
          sed -n '/Sinks:/,/Sources:/p' | \
          grep -E '^\s*[│├└]?\s*\*?\s*[0-9]+\.' | \
          grep -v 'Dummy')

        # Format for fuzzel: "ID: Name"
        menu_items=$(echo "$sink_lines" | while read line; do
          id=$(echo "$line" | sed 's/^[^0-9]*\([0-9]*\).*/\1/')
          name=$(echo "$line" | sed 's/^[^.]*\. *//; s/\[vol:.*//' | sed 's/ *$//')
          is_default=$(echo "$line" | grep -q '\*' && echo "* " || echo "")
          echo "$id: $is_default$name"
        done)

        if [ -z "$menu_items" ]; then
          ${pkgs.libnotify}/bin/notify-send "Audio" "No audio outputs found"
          exit 0
        fi

        selected=$(echo "$menu_items" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "Audio Output: ")
        if [ -n "$selected" ]; then
          selected_id=$(echo "$selected" | cut -d: -f1)
          ${pkgs.wireplumber}/bin/wpctl set-default "$selected_id"
          ${pkgs.libnotify}/bin/notify-send "Audio Output" "$(echo "$selected" | cut -d: -f2-)"
        fi
        ;;
      *)
        echo "Usage: audio-switcher [--status|--switch|--menu]"
        ;;
    esac
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "graphical-session.target";

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 8;

        modules-left = [ "custom/launcher" "custom/weather" "custom/btc" "mpris" ];
        modules-center = [ "clock" ];
        modules-right = [ "tray" "custom/audio-output" "pulseaudio" "bluetooth" "network" "battery" "power-profiles-daemon" "custom/notification" "custom/power" ];

        "custom/launcher" = {
          format = "󱓞";
          tooltip = false;
          on-click = "fuzzel";
        };

        "custom/weather" = {
          format = "{}";
          interval = 900;
          exec = "curl -s 'wttr.in/?format=%c+%t' 2>/dev/null || echo '...'";
          tooltip = false;
        };

        "custom/btc" = {
          format = "₿ {}";
          interval = 300;
          exec = "curl -s 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd' 2>/dev/null | jq -r '.bitcoin.usd | floor | tostring + \" USD\"' 2>/dev/null || echo '...'";
          tooltip = false;
        };

        "custom/power" = {
          format = "⏻";
          tooltip = false;
          on-click = "wlogout";
        };

        "custom/notification" = {
          format = "󰂚";
          tooltip = false;
          on-click = "swaync-client -t -sw";
        };

        "custom/audio-output" = {
          format = "󰓃 {}";
          return-type = "json";
          interval = 2;
          exec = "${audioSwitcher}/bin/audio-switcher --status";
          on-click = "${audioSwitcher}/bin/audio-switcher --switch";
          on-click-right = "${audioSwitcher}/bin/audio-switcher --menu";
          tooltip = true;
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱 {device_alias}";
          format-disabled = "󰂲";
          tooltip-format = "{controller_alias}\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          on-click = "blueman-manager";
        };

        mpris = {
          format = "{player_icon} {title} - {artist}";
          format-paused = "{player_icon} {title} - {artist}";
          max-length = 40;
          player-icons = {
            default = "▶";
            mpv = "🎵";
            firefox = "🦊";
            spotify = "🎧";
          };
          status-icons = {
            paused = "⏸";
          };
          on-click = "playerctl play-pause";
        };

        clock = {
          format = "{:%a %b %d  %H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            on-scroll = 1;
            format = {
              months = "<span color='#f4f4f4'><b>{}</b></span>";
              days = "<span color='#c0c0c0'>{}</span>";
              weeks = "<span color='#62a0ea'><b>W{}</b></span>";
              weekdays = "<span color='#f4f4f4'><b>{}</b></span>";
              today = "<span color='#62a0ea'><b><u>{}</u></b></span>";
            };
          };
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "󰂄  {capacity}%";
          format-plugged = "󰚥  {capacity}%";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        };

        network = {
          format-wifi = "󰖩  {essid}";
          format-ethernet = "󰈀  {ipaddr}";
          format-disconnected = "󰖪  Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "󰝟  Muted";
          format-icons = {
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pwvucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "swayosd-client --output-volume raise";
          on-scroll-down = "swayosd-client --output-volume lower";
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}";
          format-icons = {
            default = "󰗑";
            performance = "󰓅";
            balanced = "󰗑";
            power-saver = "󰌪";
          };
        };

        tray = {
          spacing = 8;
        };
      };
    };

    style = ''
      * {
        font-family: sans-serif;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
        margin: 0;
        padding: 0;
      }

      window#waybar {
        background: rgba(30, 30, 30, 0.85);
        border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      }

      tooltip {
        background: rgba(30, 30, 30, 0.95);
        border: 1px solid rgba(255, 255, 255, 0.1);
        padding: 8px;
      }

      tooltip label {
        color: #f4f4f4;
      }

      #custom-weather,
      #custom-btc {
        padding: 0 10px;
        color: #c0c0c0;
      }

      #custom-launcher {
        padding: 0 12px;
        margin-left: 4px;
        color: #62a0ea;
        font-size: 16px;
      }

      #custom-launcher:hover {
        color: #99c1f1;
      }

      #custom-weather {
        padding: 0 10px;
      }

      #mpris {
        padding: 0 10px;
        color: #c0c0c0;
      }

      #mpris.paused {
        color: #808080;
      }

      #clock {
        color: #f4f4f4;
        font-weight: 500;
      }

      #battery,
      #network,
      #bluetooth,
      #pulseaudio,
      #power-profiles-daemon,
      #custom-notification,
      #tray {
        padding: 0 10px;
        color: #c0c0c0;
      }

      #bluetooth.disabled {
        color: #505050;
      }

      #bluetooth.connected {
        color: #62a0ea;
      }

      #battery.charging {
        color: #8ff0a4;
      }

      #battery.warning:not(.charging) {
        color: #f9f06b;
      }

      #battery.critical:not(.charging) {
        color: #ff7b63;
      }

      #network.disconnected {
        color: #808080;
      }

      #pulseaudio.muted {
        color: #808080;
      }

      #tray {
        margin-right: 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      #custom-power {
        padding: 0 12px;
        color: #c0c0c0;
      }

      #custom-power:hover {
        color: #ff7b63;
      }

      #custom-audio-output {
        padding: 0 10px;
        color: #c0c0c0;
      }

      #custom-audio-output.no-audio {
        color: #808080;
      }
    '';
  };

  home.packages = with pkgs; [
    networkmanager
    pwvucontrol
    pavucontrol
    blueman
    libnotify
    power-profiles-daemon
    wlogout
    swayosd
    swaynotificationcenter
    curl
    jq
    audioSwitcher
  ];

  # SwayOSD service for volume/brightness popup
  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD LibInput backend for brightness/volume popups";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Sway Notification Center service
  systemd.user.services.swaync = {
    Unit = {
      Description = "Sway Notification Center";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
