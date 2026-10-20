{ ... }:

{
  # Vivado is a manual Xilinx install (like Obsidian), not Nix-managed — no
  # .desktop file ships with it at all, so launchers had no way to find it. Same
  # xdg.dataFile-into-~/.local/share/applications approach as Chrome above,
  # for the same reason (guaranteed discovery regardless of XDG_DATA_DIRS).
  # The version number is hardcoded (2024.2) same as Obsidian's /opt path is
  # fixed — bump it here if/when Vivado gets upgraded.
  xdg.dataFile."applications/vivado.desktop".text = ''
    [Desktop Entry]
    Name=Vivado
    Comment=Xilinx Vivado Design Suite
    Exec=/tools/Xilinx/Vivado/2024.2/bin/vivado
    Icon=/tools/Xilinx/Vivado/2024.2/doc/images/vivado_logo_bk.png
    Terminal=false
    Type=Application
    Categories=Development;Electronics;
  '';
}
