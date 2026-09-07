{ pkgs, ... }:

let
  mocha = {
    base = "1e1e2e";
    mantle = "181825";
    crust = "11111b";
    text = "cdd6f4";
    surface0 = "313244";
    surface1 = "45475a";
    overlay0 = "6c7086";
    blue = "89b4fa";
    lavender = "b4befe";
    red = "f38ba8";
    green = "a6e3a1";
  };
in
{
  home.packages = with pkgs; [
    grim
    slurp
    satty
    wl-clipboard
    brightnessctl
    networkmanagerapplet
    blueman
    polkit_gnome
  ];

  # On NixOS, hardware.graphics.enable wires these up automatically. Standalone
  # home-manager on a non-NixOS distro has no equivalent, so without this
  # Hyprland's Nix-built Mesa can't find its own Intel driver (iris_dri.so) or
  # EGL vendor ICD, and OpenGL/EGL init silently fails ("no gbm support",
  # "Supported EGL extensions: (0)") even though the driver files exist in the
  # store — they're just in the separate mesa.drivers output nothing else pulls in.
  # Confirmed working via ~/.config/environment.d/ (unlike PATH, see below).
  systemd.user.sessionVariables = {
    LIBGL_DRIVERS_PATH = "${pkgs.mesa.drivers}/lib/dri";
    __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];

    settings = {
      monitor = ",preferred,auto,1";

      # Every exec/bind below uses a full Nix store path rather than a bare command
      # name. Tried env=PATH,... (Hyprland's own directive, meant to apply to
      # itself and everything it execs) and systemd.user.sessionVariables.PATH
      # (~/.config/environment.d/) first — neither actually reached the `/bin/sh -c`
      # Hyprland's exec dispatcher spawns commands through (confirmed via journal:
      # "/bin/sh: 1: kitty: not found" even with the env directive active and
      # verified present in the generated config). Full paths sidestep PATH
      # resolution entirely, so this can't regress the same way again.
      exec-once = [
        "${pkgs.mako}/bin/mako"
        "${pkgs.networkmanagerapplet}/bin/nm-applet"
        "${pkgs.blueman}/bin/blueman-applet"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];

      "$terminal" = "${pkgs.kitty}/bin/kitty";
      "$launcher" = "${pkgs.rofi-wayland}/bin/rofi -show drun";
      "$fileManager" = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi";

      debug.disable_logs = false;

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgb(${mocha.lavender})";
        "col.inactive_border" = "rgb(${mocha.surface0})";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 4;
          passes = 2;
        };
      };

      animations.enabled = true;

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $launcher"
        "$mod, E, exec, $fileManager"
        "$mod, Q, killactive"
        "$mod SHIFT, Q, exit"
        "$mod CTRL, L, exec, ${pkgs.hyprlock}/bin/hyprlock"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"

        ", Print, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.satty}/bin/satty --filename - -o ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
      ];

      bindl = [
        ", XF86AudioMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    # Unlike services.hyprpaper/hypridle, waybar's systemd integration is opt-in.
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
        };
        clock.format = "{:%a %d %b  %H:%M}";
        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };
        network = {
          format-wifi = " {essid}";
          format-ethernet = " connected";
          format-disconnected = "⚠ disconnected";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons.default = [ "" "" "" ];
        };
        tray.spacing = 8;
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }
      window#waybar {
        /* GTK3's CSS parser (waybar 0.11) accepts rgba() only with decimal
           components, not 8-digit hex-with-alpha. 30,30,46 = #1e1e2e (mocha base). */
        background-color: rgba(30, 30, 46, 0.9);
        color: #${mocha.text};
      }
      #workspaces button {
        color: #${mocha.overlay0};
        padding: 0 6px;
      }
      #workspaces button.active {
        color: #${mocha.lavender};
      }
      #clock, #battery, #network, #pulseaudio, #tray {
        padding: 0 10px;
        color: #${mocha.text};
      }
    '';
  };

  services.mako = {
    enable = true;
    backgroundColor = "#${mocha.base}";
    textColor = "#${mocha.text}";
    borderColor = "#${mocha.lavender}";
    borderSize = 2;
    borderRadius = 8;
    defaultTimeout = 5000;
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = "catppuccin-mocha";
    extraConfig = {
      show-icons = true;
      display-drun = "Apps";
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "~/Pictures/wallpaper.jpg" ];
      wallpaper = [ ",~/Pictures/wallpaper.jpg" ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      background = [
        {
          path = "screenshot";
          blur_passes = 2;
        }
      ];
      input-field = [
        {
          size = "250, 50";
          outer_color = "rgb(${mocha.lavender})";
          inner_color = "rgb(${mocha.surface0})";
          font_color = "rgb(${mocha.text})";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      # hypridle runs as its own systemd service, inheriting the same bare PATH
      # as everything else here — same fix as Hyprland's own exec dispatcher:
      # full paths for the Nix-only binaries (hyprlock, hyprctl); pidof/loginctl/
      # systemctl are standard system utilities already on the bare PATH.
      general = {
        lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  services.cliphist.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config = {
      common.default = [ "hyprland" "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
    };
  };
}
