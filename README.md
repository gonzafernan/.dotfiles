# My dotfiles!

## Environment setup

Everything is installed and configured via Nix (home-manager):

```sh
nix run home-manager -- switch --flake ".?submodules=1#ggf"
```

(the `submodules=1` is required — this repo has git submodules, and Nix's flake
git fetcher excludes submodule content by default)

## Tools tracked

- Neovim
- tmux
- kitty
- yazi
- git
- Obsidian (config only — the app itself is a manual install at `/opt/obsidian`,
  not managed by Nix)
