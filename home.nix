{ ... }:

# Shared by every host; host-only modules are imported from hosts/.
{
  imports = [
    ./modules/packages.nix
    ./modules/chrome.nix
    ./modules/hyprland.nix
    ./modules/noctalia.nix
    ./modules/tmux.nix
    ./modules/kitty.nix
    ./modules/yazi.nix
    ./modules/nvim.nix
    ./modules/git.nix
    ./modules/obsidian.nix
  ];

  home.stateVersion = "24.11";

  # Links Nix's Mesa into /run/opengl-driver (one-time sudo step, see README.md)
  # so Nix-built GL apps work without per-session driver variables.
  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;
}
