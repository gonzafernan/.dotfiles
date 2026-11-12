{ config, pkgsUnstable, ... }:

{
  programs.kitty = {
    enable = true;
    package = pkgsUnstable.kitty;
    # bash stays the login shell, so kitty must be told to start zsh.
    settings.shell = "${config.programs.zsh.package}/bin/zsh";
    # no-cursor: zsh draws the vi-mode cursor shape itself.
    shellIntegration.mode = "no-rc no-cursor";
    extraConfig = builtins.readFile ../config/kitty/kitty.conf;
  };
  xdg.configFile."kitty/mocha.conf".source = ../config/kitty/mocha.conf;
}
