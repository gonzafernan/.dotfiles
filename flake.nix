{
  # This repo has a git submodule (nvim/.config/nvim).
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
    # No nixpkgs follows: noctalia only builds against nixos-unstable.
    noctalia.url = "github:noctalia-dev/noctalia-shell/v5.3.0";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, noctalia, ... }:
    let
      system = "x86_64-linux";
      # Narrow unfree allowance (not a blanket `allowUnfree = true`) so adding one
      # proprietary package (google-chrome) doesn't silently open the door to any
      # other unfree package landing in home.packages unnoticed.
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [ "google-chrome" ];
      pkgs = import nixpkgs { inherit system config; };
      pkgsUnstable = import nixpkgs-unstable { inherit system config; };
      # The lock screen hardcodes the "login" PAM service, whose Ubuntu stack Nix's
      # libpam can't parse (see README); give it its own /etc/pam.d/noctalia instead.
      # Hyprland 0.45 clears focus grabs as soon as they start, closing every panel
      # on open; skipping the protocol falls back to noctalia's click shield.
      noctaliaPkg = noctalia.packages.${system}.default.overrideAttrs (old: {
        postPatch = old.postPatch + ''
          substituteInPlace src/shell/lockscreen/lock_screen.cpp \
            --replace-fail 'pamService = "login"' 'pamService = "noctalia"'
          substituteInPlace src/wayland/wayland_connection.cpp \
            --replace-fail 'if (interfaceName == hyprland_focus_grab_manager_v1_interface.name) {' \
                           'if (false && interfaceName == hyprland_focus_grab_manager_v1_interface.name) {'
        '';
      });
    in {
      homeConfigurations.ggf = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit pkgsUnstable noctaliaPkg; };
        modules = [ noctalia.homeModules.default ./home.nix ];
      };
    };
}
