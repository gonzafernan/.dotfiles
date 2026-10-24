{ pkgs, pkgsUnstable, noctaliaPkg, ... }:

let
  fileManager = "${pkgsUnstable.kitty}/bin/kitty -e ${pkgsUnstable.yazi}/bin/yazi";
  mocha = {
    surface0 = "313244";
    lavender = "b4befe";
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

  # Without a cursor theme Hyprland renders its own logo as the pointer.
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaLavender;
    name = "catppuccin-mocha-lavender-cursors";
    size = 32;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-lavender-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "lavender" ];
      };
    };
  };

  # Non-NixOS has no hardware.graphics: point Nix-built Mesa at its drivers explicitly.
  # NIXOS_OZONE_WL makes Chrome/Electron render natively on Wayland (sharp at 1.5 scale).
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
      # 1.5 for the ~240 PPI panel; Wayland-native apps scale themselves from this,
      # so don't add per-app scale/font compensations on top (they'd double-scale).
      # HDMI-A-1 (1280x720) has no clean 1.5 divisor.
      monitor = [
        "HDMI-A-1,preferred,auto,1"
        ",preferred,auto,1.5"
      ];

      # Vivado's Java main window asks to float at a size larger than the screen.
      windowrulev2 = [ "tile, class:^(Vivado)$, title:.*Vivado [0-9.]+$" ];

      # home.sessionVariables never reach a GDM-launched session.
      env = [ "XCURSOR_SIZE,32" ];

      # Full store paths everywhere: Hyprland's exec shell doesn't get the Nix PATH.
      exec-once = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${pkgs.coreutils}/bin/sleep 1 && ${pkgs.hyprland}/bin/hyprctl keyword animations:enabled true"
      ];

      "$terminal" = "${pkgsUnstable.kitty}/bin/kitty";
      "$launcher" = "${noctaliaPkg}/bin/noctalia msg panel-toggle launcher";
      "$fileManager" = fileManager;

      debug.disable_logs = false;

      # Lets noctalia re-take the lock if it crashes and systemd restarts it.
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

      # Re-enabled by exec-once; skips the fade on the very first frame (hyprwm/Hyprland#6866).
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

        # Full managers, beyond noctalia's quick toggles.
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

  # Automounts removable drives (udisks2 is already a system service).
  services.udiskie = {
    enable = true;
    tray = "auto";
    notify = true;
    automount = true;
    settings.program_options.file_manager = fileManager;
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
