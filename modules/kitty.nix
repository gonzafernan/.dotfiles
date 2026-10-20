{ pkgsUnstable, ... }:

{
  programs.kitty = {
    enable = true;
    package = pkgsUnstable.kitty;
    extraConfig = builtins.readFile ../config/kitty/kitty.conf;
  };
  xdg.configFile."kitty/mocha.conf".source = ../config/kitty/mocha.conf;
}
