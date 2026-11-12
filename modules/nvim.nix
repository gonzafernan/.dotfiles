{ config, pkgs, pkgsUnstable, ... }:

{
  home.packages = with pkgs; [
    # 24.11's 0.10.2 crashes on tinymist semantic tokens (neovim#30675).
    pkgsUnstable.neovim
    lua-language-server
    bash-language-server
    clang-tools
    texlab
    # Keep tinymist/typstyle on the same channel as typst: tinymist embeds its own typst.
    tinymist
    typstyle
    ruff
    pyright
    pkgsUnstable.stylua
    yamlfmt
  ];

  # Linked to the checkout, not the store: lazy.nvim writes lazy-lock.json next to init.lua.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/nvim";
}
