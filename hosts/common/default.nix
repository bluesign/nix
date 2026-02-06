# Common configuration shared across all hosts
{ config, lib, pkgs, ... }:

let
  # Sunshine resolution scripts for tablet streaming (OnePlus Pad 3: 3392x2400)
  sunshine-res-tablet = pkgs.writeShellScriptBin "sunshine-res-tablet" ''
    # Auto-detect first enabled output
    OUTPUT=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.enabled) | .name' | head -1)
    # 1792x1200 matches tablet's ~3:2 aspect ratio
    niri msg output "$OUTPUT" custom-mode 1792x1200@60
    sleep 2  # Wait for display to stabilize
    echo "Switched $OUTPUT to 1792x1200"
  '';

  sunshine-res-restore = pkgs.writeShellScriptBin "sunshine-res-restore" ''
    OUTPUT=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.enabled) | .name' | head -1)
    niri msg output "$OUTPUT" mode 5120x2160@120
    echo "Restored $OUTPUT to 5120x2160@120"
  '';

  go2rtc-grid = pkgs.writeTextFile {
    name = "go2rtc-grid";
    destination = "/grid.html";
    text = ''
      <!DOCTYPE html>
      <html><head>
      <meta charset="utf-8">
      <title>Cameras</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #000; height: 100vh; display: grid;
               grid-template-columns: repeat(3, 1fr);
               grid-template-rows: repeat(3, 1fr); }
        iframe { width: 100%; height: 100%; border: none; }
      </style>
      </head><body>
      <script>
      const port = 1984;
      const host = location.hostname;
      const cams = ['cam1','cam2','cam3','cam4','cam5','cam6','cam7','cam8','cam9'];
      cams.forEach(src => {
        const iframe = document.createElement('iframe');
        iframe.src = 'http://' + host + ':' + port + '/stream.html?src=' + src + '&mode=mse';
        document.body.appendChild(iframe);
      });
      </script>
      </body></html>
    '';
  };
in
{
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # v4l2loopback for virtual camera (pyFaceCam, OBS, etc.)
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=0 card_label="FaceCam" exclusive_caps=1
    options btusb enable_autosuspend=0
    options iwlwifi bt_coex_active=1
  '';

  # Networking
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # DNS resolver (required for Mullvad VPN)
  services.resolved.enable = true;

  # Localization
  time.timeZone = "Europe/Amsterdam";

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Shell
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "z" "fzf" "sudo" "terraform" "systemadmin" "vi-mode" ];
  };
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  # Core packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    fzf
    htop
    overskride
    wlr-randr
    sunshine-res-tablet
    sunshine-res-restore
  ];

  # Services
  services.dbus.enable = true;
  services.dbus.implementation = "broker";

  # GVFS (virtual filesystem for Nemo, Valent phone mounting, etc.)
  services.gvfs.enable = true;

  # Sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 512;
      };
    };
  };

  # Bluetooth codecs (AAC, LDAC, aptX, LC3 for LE Audio)
  environment.etc."wireplumber/wireplumber.conf.d/50-bluez.conf".text = ''
    monitor.bluez.properties = {
      bluez5.enable-sbc-xq = true
      bluez5.enable-msbc = true
      bluez5.enable-hw-volume = true
      bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source hfp_hf hfp_ag ]
      bluez5.codecs = [ sbc sbc_xq aac ldac aptx aptx_hd aptx_ll aptx_ll_duplex opus lc3 ]
      bluez5.autoswitch-profile = false
    }

    monitor.bluez.rules = [
      {
        matches = [ { device.name = "~bluez_card.*" } ]
        actions = {
          update-props = {
            bluez5.auto-connect = [ a2dp_sink hfp_hf ]
            device.profile = "a2dp-sink"
          }
        }
      }
      {
        matches = [ { node.name = "~bluez_output.*" } ]
        actions = {
          update-props = {
            session.suspend-timeout-seconds = 0
            node.pause-on-idle = false
          }
        }
      }
    ]
  '';

  # go2rtc (camera RTSP relay/proxy)
  systemd.services.go2rtc = {
    description = "go2rtc camera streaming";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.go2rtc}/bin/go2rtc -config ${
        pkgs.writeText "go2rtc.yaml" (builtins.toJSON {
          api.listen = ":1984";
          rtsp.listen = ":8554";
          webrtc.listen = ":8555";
          streams = {
            cam1 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch1/main/av_stream" ];
            cam2 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch2/main/av_stream" ];
            cam3 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch3/main/av_stream" ];
            cam4 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch4/main/av_stream" ];
            cam5 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch5/main/av_stream" ];
            cam6 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch6/main/av_stream" ];
            cam7 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch7/main/av_stream" ];
            cam8 = [ "rtsp://admin:moonmoon@192.168.0.4:554/h264/ch8/main/av_stream" ];
            cam9 = [ "rtsp://192.168.0.200:554/h264/ch1/main/av_stream" ];
            grid = [
              ("exec:${pkgs.ffmpeg}/bin/ffmpeg"
              + " -vaapi_device /dev/dri/renderD128"
              + " -filter_threads 8 -filter_complex_threads 8"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch1/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch2/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch3/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch4/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch5/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch6/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch7/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://admin:moonmoon@192.168.0.4:554/h264/ch8/sub/av_stream"
              + " -rtsp_transport tcp -i rtsp://192.168.0.200:554/h264/ch1/main/av_stream"
              + " -filter_complex "
              + "[0:v]scale=640:360[v0];[1:v]scale=640:360[v1];[2:v]scale=640:360[v2];"
              + "[3:v]scale=640:360[v3];[4:v]scale=640:360[v4];[5:v]scale=640:360[v5];"
              + "[6:v]scale=640:360[v6];[7:v]scale=640:360[v7];[8:v]scale=640:360[v8];"
              + "[v0][v1][v2][v3][v4][v5][v6][v7][v8]xstack=inputs=9:"
              + "layout=0_0|640_0|1280_0|0_360|640_360|1280_360|0_720|640_720|1280_720,"
              + "format=nv12,hwupload"
              + " -c:v h264_vaapi -qp 28 -g 30 -bf 0 -f mpegts pipe:1"
              )
            ];
          };
        })
      }";
      Restart = "on-failure";
      RestartSec = 5;
      DynamicUser = true;
      SupplementaryGroups = [ "video" "render" ];
    };
  };

  # Camera grid page (serves grid.html on port 1985)
  systemd.services.go2rtc-grid = {
    description = "go2rtc camera grid page";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python -m http.server 1985 -d ${go2rtc-grid}";
      Restart = "on-failure";
      DynamicUser = true;
    };
  };

  # Allow go2rtc + grid ports only on Tailscale interface
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 1984 1985 8554 8555 ];
    allowedUDPPorts = [ 8555 ];
  };

  # Tailscale VPN
  services.tailscale.enable = true;

  # Mullvad VPN
  services.mullvad-vpn.enable = true;

  # SSH server
  services.openssh.enable = true;

  # Sunshine (remote desktop streaming for Moonlight)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for Wayland capture
    openFirewall = true;
  };

  # Power management (required for battery monitoring)
  services.upower.enable = true;

  # Power profiles (use `powerprofilesctl` to switch between power-saver/balanced/performance)
  services.power-profiles-daemon.enable = true;

  # Zram swap (compressed RAM swap, better than disk)
  zramSwap.enable = true;

  # Early OOM killer (prevents system freeze on low memory)
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Keep --compat for legacy SDP socket (useful for sdptool etc)
  systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd --compat"
  ];


  # Bluetooth udev rules:
  # - Disable USB autosuspend for all BT adapters (class e0 = wireless controller)
  # - BT HID low latency connection intervals (7.5ms-11.25ms)
  # PandwaRF / Yard Stick One / RfCat devices (OpenMoko vendor ID)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="e0", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="e0", ATTR{../power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{../../device/conn_min_interval}="6"
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{../../device/conn_max_interval}="9"
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{../../device/conn_latency}="0"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="60ff", MODE="0666"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="6047", MODE="0666"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="6048", MODE="0666"
  '';


  # Printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
      hplip
      splix  # Samsung ML/CLP printers including M2020
    ];
  };

  # cups-browsed for network printer discovery
  services.printing.browsed.enable = true;

  # Network printer discovery (Avahi/mDNS)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
