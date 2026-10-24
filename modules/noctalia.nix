{ noctaliaPkg, lib, ... }:

{
  # Manual sudo step that has been missed before; see README.md.
  home.activation.checkNoctaliaPam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f /etc/pam.d/noctalia ] || [ ! -e /run/wrappers/bin/unix_chkpwd ]; then
      echo ""
      echo "############################################################"
      echo "# WARNING: noctalia's PAM setup is missing or incomplete!  #"
      echo "# The screen lock will NEVER accept your password until    #"
      echo "# you run (see README.md for why):                         #"
      echo "#                                                          #"
      echo "#   sudo cp system/pam.d/noctalia /etc/pam.d/              #"
      echo "#   sudo cp system/tmpfiles.d/nix-pam-wrappers.conf \\"
      echo "#        /etc/tmpfiles.d/                                 #"
      echo "#   sudo systemd-tmpfiles --create \\"
      echo "#        /etc/tmpfiles.d/nix-pam-wrappers.conf             #"
      echo "############################################################"
      echo ""
    fi
  '';

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
      wallpaper.default.path = "${../wallpapers/wallpaper.jpg}";
      bar.main = {
        margin_edge = 8;
        margin_ends = 8;
        start = [ "workspaces" ];
        center = [ "clock" ];
        end = [ "media" "tray" "notifications" "clipboard" "network" "bluetooth" "volume" "battery" "control-center" "session" ];
      };
      widget = {
        media.hide_when_no_media = true;
        tray.drawer = false;
        volume.show_label = false;
        network.show_label = false;
        bluetooth.show_label = false;
        battery.display_mode = "graphic";
        clock = {
          format = "{:%a %d %b · %H:%M}";
          font_weight = 600;
        };
      };
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
}
