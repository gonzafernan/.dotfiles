{ pkgs, pkgsUnstable, lib, ... }:

{
  home.packages = with pkgs; [
    # 24.11's 0.10.2 crashes on tinymist semantic tokens (neovim#30675).
    pkgsUnstable.neovim
    xclip
    lazygit
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    # Keep typst/tinymist/typstyle from the same channel: tinymist embeds its own typst.
    typst
    tinymist
    typstyle
    pkgsUnstable.iverilog
    gtkwave
    ruff
    pyright
    (lib.hiPrio pkgsUnstable.python3)
    pkgsUnstable.python312
    pkgsUnstable.verible
    pkgsUnstable.stylua
    zathura
  ];

  fonts.fontconfig.enable = true;
}
