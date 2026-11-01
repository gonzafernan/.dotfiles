{ config, ... }:

{
  # Linked to the checkout, not the store: lazy.nvim writes lazy-lock.json next to init.lua.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/nvim";
}
