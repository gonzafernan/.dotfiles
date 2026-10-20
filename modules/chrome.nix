{ pkgsUnstable, lib, ... }:

let
  # Unstable: the 24.11 pin's .deb URL 404s once Google drops that version.
  chrome = pkgsUnstable.google-chrome;
in
{
  home.packages = [ chrome ];

  # ~/.nix-profile/share isn't on XDG_DATA_DIRS in this session; launchers always scan
  # ~/.local/share/applications.
  xdg.dataFile."applications/google-chrome.desktop".source =
    "${chrome}/share/applications/google-chrome.desktop";

  # Chrome won't start without this profile; see README.md.
  home.activation.checkChromeAppArmor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f /etc/apparmor.d/nix-google-chrome ]; then
      echo ""
      echo "############################################################"
      echo "# WARNING: Chrome's AppArmor profile is missing! Chrome    #"
      echo "# will refuse to start until you run (see README.md):      #"
      echo "#                                                          #"
      echo "#   sudo cp system/apparmor.d/nix-google-chrome \\"
      echo "#        /etc/apparmor.d/                                  #"
      echo "#   sudo apparmor_parser -r /etc/apparmor.d/nix-google-chrome"
      echo "############################################################"
      echo ""
    fi
  '';
}
