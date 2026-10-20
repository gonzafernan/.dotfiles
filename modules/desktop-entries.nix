{ ... }:

{
  # Vivado is a manual install that ships no .desktop file; bump the version on upgrade.
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
