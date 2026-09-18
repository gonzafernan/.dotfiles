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
    neovim
    xclip
    lazygit
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    chrome
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
    settings = builtins.fromTOML (builtins.readFile ./yazi/.config/yazi/yazi.toml);
    theme = builtins.fromTOML (builtins.readFile ./yazi/.config/yazi/theme.toml);
  };
  xdg.configFile."yazi/package.toml".source = ./yazi/.config/yazi/package.toml;

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
