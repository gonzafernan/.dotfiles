{ pkgs, pkgsUnstable, lib, ... }:

let
  obsidian = pkgsUnstable.obsidian;
in
{
  home.packages = [ obsidian ];

  # Same reason as Chrome: launchers only scan ~/.local/share/applications. The
  # launcher's PATH lacks ~/.nix-profile/bin, so point Exec/Icon at the store.
  xdg.dataFile."applications/obsidian.desktop".source =
    pkgs.runCommand "obsidian.desktop" { } ''
      substitute ${obsidian}/share/applications/md.obsidian.Obsidian.desktop $out \
        --replace-fail "Exec=obsidian" "Exec=${obsidian}/bin/obsidian" \
        --replace-fail "Icon=obsidian" "Icon=${obsidian}/share/icons/hicolor/512x512/apps/obsidian.png"
    '';

  xdg.configFile."obsidian/obsidian.vimrc".source = ../config/obsidian/obsidian.vimrc;

  # Electron's sandbox needs this profile, like Chrome; see README.md.
  home.activation.checkElectronAppArmor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f /etc/apparmor.d/nix-electron ]; then
      echo "WARNING: Obsidian won't start until you install system/apparmor.d/nix-electron (README.md)."
    fi
  '';
}
