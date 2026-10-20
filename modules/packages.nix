{ pkgs, pkgsUnstable, lib, ... }:

{
  home.packages = with pkgs; [
    # TRYING pkgsUnstable here (0.12.5) instead of the pkgs (24.11) pin: works
    # around a confirmed Neovim 0.10.2 core bug (off-by-one in
    # semantic_tokens.lua, github.com/neovim/neovim/issues/30675, fixed
    # upstream in 0.10.3+) that crashes on tinymist's semantic tokens for
    # typst syntax like `#table`. This exact jump (24.11's 0.10.2 -> a recent
    # unstable) previously broke vanilla.nvim's own Lua module loading
    # entirely (require('lazy')/require('lsp.formatting') failing) — that was
    # the whole reason Neovim got pinned to 24.11 in the first place. Being
    # re-tried now since the submodule has since been rebased/changed a lot;
    # if it breaks again, revert to `neovim` (the pkgs/24.11 one) below.
    pkgsUnstable.neovim
    xclip
    lazygit
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    # Was cargo-installed (~/.cargo/bin) — moved to Nix for reproducibility.
    # nixpkgs-24.11 has these one minor version behind cargo's 0.13.x (0.12.x
    # here), but all three stay mutually version-matched with each other,
    # which matters more than chasing the exact latest (tinymist embeds its
    # own typst engine internally, so typst/tinymist/typstyle drifting apart
    # is the real risk, not being a minor version behind upstream).
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
    # Was apt-installed (/usr/bin/zathura) — moved to Nix for the same
    # reproducibility reason. Unlike the cargo tools above, /usr/bin already
    # comes after ~/.nix-profile/bin on PATH, so this alone makes the Nix
    # build take precedence with no need to remove/touch the apt package.
    # pkgs.zathura bundles the mupdf PDF backend by default (it's actually
    # "zathura-with-plugins" under the hood), so no separate plugin needed.
    zathura
  ];

  fonts.fontconfig.enable = true;
}
