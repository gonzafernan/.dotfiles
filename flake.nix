{
  # This repo has git submodules (nvim/.config/nvim, tmux/.tmux/plugins/tpm).
  # Nix's flake git fetcher excludes submodule content by default, so always
  # activate with: nix run home-manager -- switch --flake ".?submodules=1#ggf"

  description = "Personal system home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Scoped to google-chrome only (see below) — a fast-moving proprietary binary
    # like Chrome rots quickly on a fixed stable pin: nixpkgs' google-chrome
    # derivation fetches one specific .deb by URL, and Google removes old
    # versions from its download mirror as new ones ship, so the 24.11 pin's
    # referenced version 404s within weeks. nixos-unstable updates multiple
    # times a day and tracks the currently-available version far more closely.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      # Narrow unfree allowance (not a blanket `allowUnfree = true`) so adding one
      # proprietary package (google-chrome) doesn't silently open the door to any
      # other unfree package landing in home.packages unnoticed.
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [ "google-chrome" ];
      pkgs = import nixpkgs { inherit system config; };
      pkgsUnstable = import nixpkgs-unstable { inherit system config; };
    in {
      homeConfigurations.ggf = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit pkgsUnstable; };
        modules = [ ./home.nix ];
      };
    };
}
