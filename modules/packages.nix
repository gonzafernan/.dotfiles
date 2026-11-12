{ pkgs, pkgsUnstable, ... }:

{
  home.packages = with pkgs; [
    xclip
    lazygit
    nerd-fonts.jetbrains-mono
    typst
    pkgsUnstable.python3
    zathura
  ];

  fonts.fontconfig.enable = true;
}
