{ pkgs, ... }:

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
  ];

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
