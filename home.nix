{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/chrome.nix
    ./modules/desktop-entries.nix
    ./modules/hyprland.nix
    ./modules/noctalia.nix
    ./modules/tmux.nix
    ./modules/kitty.nix
    ./modules/yazi.nix
    ./modules/nvim.nix
    ./modules/git.nix
    ./modules/obsidian.nix
  ];

  home.username = "ggf";
  home.homeDirectory = "/home/ggf";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
