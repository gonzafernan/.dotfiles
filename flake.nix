{
  # This repo has git submodules (nvim/.config/nvim, tmux/.tmux/plugins/tpm).
  # Nix's flake git fetcher excludes submodule content by default, so always
  # activate with: nix run home-manager -- switch --flake ".?submodules=1#ggf"

  description = "Personal system home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.ggf = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
