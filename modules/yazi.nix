{ pkgsUnstable, ... }:

{
  programs.yazi = {
    enable = true;
    package = pkgsUnstable.yazi;
  };
  xdg.configFile = {
    "yazi/yazi.toml".source = ../config/yazi/yazi.toml;
    "yazi/theme.toml".source = ../config/yazi/theme.toml;
    "yazi/keymap.toml".source = ../config/yazi/keymap.toml;
    "yazi/package.toml".source = ../config/yazi/package.toml;
    "yazi/flavors/catppuccin-mocha.yazi".source = ../config/yazi/flavors/catppuccin-mocha.yazi;
  };
}
