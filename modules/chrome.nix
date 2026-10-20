{ pkgsUnstable, lib, ... }:

let
  # From pkgsUnstable (see flake.nix) — nixpkgs' google-chrome fetches one
  # specific .deb by URL, which Google routinely removes from its mirror,
  # 404ing on any pin more than a few weeks old; nixos-unstable tracks the
  # currently-available version closely enough for this to actually build.
  #
  # No --force-device-scale-factor: that was a per-app compensation for the
  # ~240 PPI panel from before hyprland.nix's `monitor` had a real scale set.
  # With that scale in place, Chrome (native Wayland via NIXOS_OZONE_WL) reads
  # it and scales itself automatically — keeping the flag too would double-scale.
  chrome = pkgsUnstable.google-chrome;
in
{
  home.packages = [ chrome ];

  # xdg.desktopEntries would install this under ~/.nix-profile/share/applications,
  # which needs ~/.nix-profile/share in XDG_DATA_DIRS to be found by launchers —
  # and that variable is silently refused via both systemd's environment.d and
  # Hyprland's own `env` directive on this system (same class of failure PATH
  # hit, see hyprland.nix). ~/.local/share/applications (XDG_DATA_HOME) needs no
  # such env var at all — every XDG-compliant launcher scans it unconditionally —
  # so symlinking straight there sidesteps the whole problem.
  xdg.dataFile."applications/google-chrome.desktop".source =
    "${chrome}/share/applications/google-chrome.desktop";

  # Chrome's sandbox can't start without this profile (Ubuntu restricts
  # unprivileged user namespaces) — see README.md.
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
