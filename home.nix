{ pkgs, pkgsUnstable, ... }:

let
  # From pkgsUnstable (see flake.nix) — nixpkgs' google-chrome fetches one
  # specific .deb by URL, which Google routinely removes from its mirror,
  # 404ing on any pin more than a few weeks old; nixos-unstable tracks the
  # currently-available version closely enough for this to actually build.
  #
  # No --force-device-scale-factor: that was a per-app compensation for the
  # ~240 PPI panel from before hyprland.nix's `monitor` had a real scale set.
  # With that scale in place, Chrome (native Wayland via NIXOS_OZONE_WL) reads
  # it and scales itself automatically — keeping the flag too would double-scale.
  chrome = pkgsUnstable.google-chrome.override {
    # --no-sandbox: Chrome's SUID sandbox helper must be a setuid-root binary,
    # which Nix store files can never be (read-only/immutable) — NixOS solves
    # this via security.wrappers (a setuid copy at /run/wrappers/bin/...), but
    # that path changes on every Chrome update, so a static system file pointing
    # at today's store hash would need re-applying almost weekly. Disabling the
    # sandbox is the standard low-maintenance answer for Chrome-via-Nix on a
    # non-NixOS, single-user machine (reduced renderer isolation, not "no security").
    commandLineArgs = "--no-sandbox";
  };
in
{
  imports = [ ./hyprland.nix ];

  home.username = "ggf";
  home.homeDirectory = "/home/ggf";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

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
    chrome
    # Was cargo-installed (~/.cargo/bin) — moved to Nix for reproducibility.
    # nixpkgs-24.11 has these one minor version behind cargo's 0.13.x (0.12.x
    # here), but all three stay mutually version-matched with each other,
    # which matters more than chasing the exact latest (tinymist embeds its
    # own typst engine internally, so typst/tinymist/typstyle drifting apart
    # is the real risk, not being a minor version behind upstream).
    typst
    tinymist
    typstyle
    ruff
    pyright
    # Was apt-installed (/usr/bin/zathura) — moved to Nix for the same
    # reproducibility reason. Unlike the cargo tools above, /usr/bin already
    # comes after ~/.nix-profile/bin on PATH, so this alone makes the Nix
    # build take precedence with no need to remove/touch the apt package.
    # pkgs.zathura bundles the mupdf PDF backend by default (it's actually
    # "zathura-with-plugins" under the hood), so no separate plugin needed.
    zathura
  ];

  # xdg.desktopEntries would install this under ~/.nix-profile/share/applications,
  # which needs ~/.nix-profile/share in XDG_DATA_DIRS to be found by rofi/etc —
  # and that variable is silently refused via both systemd's environment.d and
  # Hyprland's own `env` directive on this system (same class of failure PATH
  # hit, see hyprland.nix). ~/.local/share/applications (XDG_DATA_HOME) needs no
  # such env var at all — every XDG-compliant launcher scans it unconditionally —
  # so symlinking straight there sidesteps the whole problem.
  xdg.dataFile."applications/google-chrome.desktop".source =
    "${chrome}/share/applications/google-chrome.desktop";

  # Vivado is a manual Xilinx install (like Obsidian), not Nix-managed — no
  # .desktop file ships with it at all, so rofi had no way to find it. Same
  # xdg.dataFile-into-~/.local/share/applications approach as Chrome above,
  # for the same reason (guaranteed discovery regardless of XDG_DATA_DIRS).
  # The version number is hardcoded (2024.2) same as Obsidian's /opt path is
  # fixed — bump it here if/when Vivado gets upgraded.
  xdg.dataFile."applications/vivado.desktop".text = ''
    [Desktop Entry]
    Name=Vivado
    Comment=Xilinx Vivado Design Suite
    Exec=/tools/Xilinx/Vivado/2024.2/bin/vivado
    Icon=/tools/Xilinx/Vivado/2024.2/doc/images/vivado_logo_bk.png
    Terminal=false
    Type=Application
    Categories=Development;Electronics;
  '';

  fonts.fontconfig.enable = true;

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./tmux/.tmux.conf;
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty/.config/kitty/kitty.conf;
  };
  xdg.configFile."kitty/mocha.conf".source = ./kitty/.config/kitty/mocha.conf;

  programs.yazi = {
    enable = true;
    package = pkgsUnstable.yazi;
    settings = builtins.fromTOML (builtins.readFile ./yazi/.config/yazi/yazi.toml);
    theme = builtins.fromTOML (builtins.readFile ./yazi/.config/yazi/theme.toml);
    keymap = builtins.fromTOML (builtins.readFile ./yazi/.config/yazi/keymap.toml);
  };
  xdg.configFile."yazi/package.toml".source = ./yazi/.config/yazi/package.toml;
  # theme.toml's [flavor] references catppuccin-mocha, but that's yazi's own
  # package manager's job to fetch (`ya pkg install`) — home-manager only ever
  # wired up yazi.toml/theme.toml/package.toml themselves, never this. The
  # actual flavor.toml was already vendored in this repo since before the Nix
  # migration (July 2025, GNU Stow era) but never referenced, so it silently
  # sat unused until yazi errored looking for it at ~/.config/yazi/flavors/.
  xdg.configFile."yazi/flavors/catppuccin-mocha.yazi".source =
    ./yazi/.config/yazi/flavors/catppuccin-mocha.yazi;

  xdg.configFile."nvim".source = ./nvim/.config/nvim;

  programs.git = {
    enable = true;
    userName = "Gonzalo G. Fernandez";
    userEmail = "fernandez.gfg@gmail.com";
    ignores = [ "**/.claude/settings.local.json" ];
    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "main";
      http.sslVerify = true;
      status.branch = true;
      status.showStash = true;
      url."git@github.com:".insteadOf = "gh:";
    };
  };

  xdg.configFile."obsidian/obsidian.vimrc".source = ./obsidian/.config/obsidian/obsidian.vimrc;
}
