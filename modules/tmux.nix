{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${config.programs.zsh.package}/bin/zsh";
    extraConfig = builtins.readFile ../config/tmux/tmux.conf;
    plugins = [
      {
        # Pinned to the commit previously installed via tpm; nixpkgs' catppuccin
        # uses an incompatible option set.
        plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "catppuccin";
          version = "unstable-2024-10-01";
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "tmux";
            rev = "d424a03a4be721638a149a3e8422915a0133279a";
            hash = "sha256-W+jUEfyWSDrr+NVG6/Lh8MMrzbX4upWFrQxxuRp4jx8=";
          };
        };
        extraConfig = builtins.readFile ../config/tmux/catppuccin.conf;
      }
    ];
  };
}
