{ pkgs, pkgsUnstable, noctaliaPkg, lib, ... }:

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

  # Without a cursor theme configured anywhere, Hyprland falls back to its own
  # built-in default — the Hyprland logo itself, rendered as the pointer. This
  # symlinks the theme to ~/.icons/default/ (home-manager's home.pointerCursor
  # module), which is the exact fallback location Hyprland already tries and
  # failed to find anything in (confirmed in an earlier crash log: "Hyprcursor
  # failed loading theme \"\", falling back to Xcursor" -> "XCursor failed
  # finding any shapes in theme \"default\""). No env var propagation needed —
  # sidesteps that whole class of problem entirely.
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaLavender;
    name = "catppuccin-mocha-lavender-cursors";
    size = 32;
  };

  # Themes the GTK3/GTK4 apps used for advanced Wifi/Bluetooth setup below
  # (nm-connection-editor, blueman-manager) to match everything else —
  # variant/accents match the mocha/lavender scheme used throughout this file.
  # GTK3 apps read this via ~/.config/gtk-3.0/settings.ini regardless of dconf.
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-lavender-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "lavender" ];
      };
    };
    cursorTheme = {
      name = "catppuccin-mocha-lavender-cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      size = 32;
    };
  };

  # This has silently failed to get applied three separate times because it's a
  # manual sudo step with no reminder — see README.md "Hyprland on non-NixOS:
  # required manual system setup". Rather than trust that it was done, check for
  # it on every single `home-manager switch` and make it impossible to miss.
  home.activation.checkNoctaliaPam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f /etc/pam.d/noctalia ] || [ ! -e /run/wrappers/bin/unix_chkpwd ]; then
      echo ""
      echo "############################################################"
      echo "# WARNING: noctalia's PAM setup is missing or incomplete!  #"
      echo "# The screen lock will NEVER accept your password until    #"
      echo "# you run (see README.md for why):                         #"
      echo "#                                                          #"
      echo "#   sudo cp hyprland/system/pam.d/noctalia /etc/pam.d/     #"
      echo "#   sudo cp hyprland/system/tmpfiles.d/nix-pam-wrappers.conf \\"
      echo "#        /etc/tmpfiles.d/                                 #"
      echo "#   sudo systemd-tmpfiles --create \\"
      echo "#        /etc/tmpfiles.d/nix-pam-wrappers.conf             #"
      echo "############################################################"
      echo ""
    fi
  '';

  # On NixOS, hardware.graphics.enable wires these up automatically. Standalone
  # home-manager on a non-NixOS distro has no equivalent, so without this
  # Hyprland's Nix-built Mesa can't find its own Intel driver (iris_dri.so) or
  # EGL vendor ICD, and OpenGL/EGL init silently fails ("no gbm support",
  # "Supported EGL extensions: (0)") even though the driver files exist in the
  # store — they're just in the separate mesa.drivers output nothing else pulls in.
  # NIXOS_OZONE_WL is a NixOS-convention variable that nixpkgs' google-chrome
  # (and Electron apps generally) check to opt into native Wayland rendering
  # instead of falling back to XWayland. Without it, Chrome would render via
  # XWayland at scale 1 and get upscaled by the compositor to match our
  # --force-device-scale-factor, which is blurry — native Wayland renders
  # crisply at the target scale directly.
  # (XDG_DATA_DIRS is NOT here — confirmed live it's silently refused via
  # environment.d exactly like PATH was; see the `env` list below instead.)
  systemd.user.sessionVariables = {
    LIBGL_DRIVERS_PATH = "${pkgs.mesa.drivers}/lib/dri";
    __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
    NIXOS_OZONE_WL = "1";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];

    settings = {
      # 1.5 scale for this ~240 PPI panel: this is the actual systemic fix for
      # "X app's content is tiny" (waybar, kitty, Chrome, now Obsidian) rather
      # than patching each app's own font/size setting individually forever —
      # any properly Wayland-native client (GTK, Qt, Electron via ozone) reads
      # this and scales itself automatically. Per-app compensations made before
      # this existed (waybar height/font, kitty font_size, Chrome's
      # --force-device-scale-factor) are being reverted alongside this, since
      # stacking both would double-scale.
      #
      # HDMI-A-1's 1280x720 has no clean divisor at 1.5, so it gets its own scale
      # instead of the wildcard (Hyprland warned and fell back to 1.0 anyway).
      monitor = [
        "HDMI-A-1,preferred,auto,1"
        ",preferred,auto,1.5"
      ];

      # Vivado's Java main window asks to float at a size larger than the screen.
      windowrulev2 = [ "tile, class:^(Vivado)$, title:.*Vivado [0-9.]+$" ];

      # home.pointerCursor's `size` only reaches home.sessionVariables (the
      # .profile-based mechanism), which — like PATH and XDG_DATA_DIRS — never
      # reaches a GDM-launched Hyprland session. Unlike those, XCURSOR_SIZE is
      # read directly by Hyprland's own process (not by an exec'd child via
      # /bin/sh -c), so Hyprland's own `env` directive reaches it fine here.
      env = [ "XCURSOR_SIZE,32" ];

      # Every exec/bind below uses a full Nix store path rather than a bare command
      # name. Tried env=PATH,... (Hyprland's own directive, meant to apply to
      # itself and everything it execs) and systemd.user.sessionVariables.PATH
      # (~/.config/environment.d/) first — neither actually reached the `/bin/sh -c`
      # Hyprland's exec dispatcher spawns commands through (confirmed via journal:
      # "/bin/sh: 1: kitty: not found" even with the env directive active and
      # verified present in the generated config). Full paths sidestep PATH
      # resolution entirely, so this can't regress the same way again.
      exec-once = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${pkgs.coreutils}/bin/sleep 1 && ${pkgs.hyprland}/bin/hyprctl keyword animations:enabled true"
      ];

      "$terminal" = "${pkgsUnstable.kitty}/bin/kitty";
      "$launcher" = "${noctaliaPkg}/bin/noctalia msg panel-toggle launcher";
      "$fileManager" = "${pkgsUnstable.kitty}/bin/kitty -e ${pkgsUnstable.yazi}/bin/yazi";

      debug.disable_logs = false;

      # Lets a restarted noctalia (systemd Restart=on-failure) take back the lock
      # if it crashes while locked, instead of leaving the session stuck.
      misc.allow_session_lock_restore = true;

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

      # false here, then flipped true a moment after login (exec-once below) —
      # this is the standard workaround (confirmed via a Hyprland maintainer
      # discussion, github.com/hyprwm/Hyprland/discussions/6866; there's no
      # dedicated "disable just the first-launch animation" flag) for the
      # brief fade Hyprland otherwise plays on its very first frame. Normal
      # animations (window open/close, workspace switch) resume immediately
      # after that ~1s delay — only the initial startup transition is skipped.
      animations.enabled = false;

      input = {
        kb_layout = "us";
        kb_variant = "altgr-intl";
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
        "$mod CTRL, L, exec, ${noctaliaPkg}/bin/noctalia msg session lock"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"

        # Full Bluetooth/network managers for pairing, VPNs, static IPs — anything
        # beyond the quick toggles in noctalia's control center.
        "$mod, B, exec, ${pkgs.blueman}/bin/blueman-manager"
        "$mod, N, exec, ${pkgs.networkmanagerapplet}/bin/nm-connection-editor"

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

        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"
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

  programs.noctalia = {
    enable = true;
    package = noctaliaPkg;
    systemd.enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      wallpaper.default.path = "${./wallpapers/wallpaper.jpg}";
      bar.main = {
        margin_edge = 8;
        margin_ends = 8;
        start = [ "launcher" "workspaces" ];
        center = [ "clock" ];
        end = [ "media" "tray" "notifications" "clipboard" "network" "bluetooth" "volume" "battery" "control-center" "session" ];
      };
      widget.media.hide_when_no_media = true;
      idle.behavior = {
        lock = {
          timeout = 300;
          action = "lock";
          enabled = true;
        };
        screen-off = {
          timeout = 330;
          action = "screen_off";
          enabled = true;
        };
        suspend = {
          timeout = 600;
          action = "suspend";
          enabled = true;
        };
      };
    };
  };

  # Auto-mounts SD cards/external drives on insert (udisks2 does the actual
  # mounting; udisks2 itself is a system service, already present since GNOME
  # depends on it — this just adds the piece GNOME's own file manager would
  # normally provide: something that actually triggers the mount and notifies).
  services.udiskie = {
    enable = true;
    tray = "never";
    notify = true;
    automount = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config = {
      common.default = [ "hyprland" "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
    };
  };

}
