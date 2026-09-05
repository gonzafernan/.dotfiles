# My dotfiles!

## Environment setup

nvim, tmux, kitty, and yazi are installed and configured via Nix (home-manager):

```sh
nix run home-manager -- switch --flake ".?submodules=1#ggf"
```

(the `submodules=1` is required — this repo has git submodules, and Nix's flake
git fetcher excludes submodule content by default)

Everything else is symlinked with GNU Stow:

```sh
$ stow .
```

## Tools tracked

Nix (home-manager):
- Neovim
- tmux
- kitty
- yazi

Stow:
- Obsidian

