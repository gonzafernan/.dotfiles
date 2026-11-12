{ config, lib, pkgs, pkgsUnstable, ... }:

let
  zsh = "${config.programs.zsh.package}/bin/zsh";
  fdCmd = "fd --hidden --exclude .git";
  dirPreview = "eza --tree --level=2 --icons=always --color=always";
in
{
  home.packages = with pkgs; [
    fd
    ripgrep
    devcontainer
    pkgsUnstable.claude-code
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
  };
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    completionInit = ''
      autoload -U compinit
      mkdir -p "${config.xdg.cacheHome}/zsh"
      compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
    '';
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = false;
      append = true;
    };
    autosuggestion = {
      enable = true;
      highlight = "fg=#6c7086";
    };
    syntaxHighlighting = {
      enable = true;
      styles = {
        unknown-token = "fg=#f38ba8";
        reserved-word = "fg=#cba6f7";
        builtin = "fg=#a6e3a1";
        command = "fg=#a6e3a1";
        alias = "fg=#a6e3a1";
        function = "fg=#a6e3a1";
        precommand = "fg=#a6e3a1,underline";
        path = "fg=#cdd6f4,underline";
        globbing = "fg=#f9e2af";
        single-hyphen-option = "fg=#fab387";
        double-hyphen-option = "fg=#fab387";
        single-quoted-argument = "fg=#f9e2af";
        double-quoted-argument = "fg=#f9e2af";
        dollar-quoted-argument = "fg=#f9e2af";
        commandseparator = "fg=#94e2d5";
        redirection = "fg=#94e2d5";
        comment = "fg=#6c7086";
      };
    };
    setOptions = [
      "INC_APPEND_HISTORY_TIME"
      "AUTO_CD"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
    ];
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      ll = "eza -la";
      la = "eza -a";
      lt = "eza --tree --level=2";
    };
    initContent = lib.mkMerge [
      # fzf-tab must come after compinit (570) but before autosuggestions (700) wrap the widgets.
      (lib.mkOrder 600 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu no
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' switch-group '<' '>'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview '${dirPreview} $realpath'
      '')
      # After fzf's widgets (910); the cursor hook must exist before starship (1000) wraps it.
      (lib.mkOrder 940 ''
        export SHELL=${zsh}
        KEYTIMEOUT=15
        bindkey -M viins jk vi-cmd-mode

        function zle-keymap-select zle-line-init {
          [[ $KEYMAP == vicmd ]] && printf '\e[2 q' || printf '\e[6 q'
        }
        function zle-line-finish { printf '\e[2 q' }
        zle -N zle-keymap-select
        zle -N zle-line-init
        zle -N zle-line-finish

        bindkey -M viins '^?' backward-delete-char
        bindkey -M viins '^H' backward-delete-char
        bindkey -M viins '^W' backward-kill-word
        bindkey -M viins '^U' backward-kill-line

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd v edit-command-line

        autoload -Uz select-quoted select-bracketed
        zle -N select-quoted
        zle -N select-bracketed
        for km in viopp visual; do
          for c in {a,i}{\',\",\`}; do bindkey -M $km $c select-quoted; done
          for c in {a,i}{\(,\),\[,\],\{,\},\<,\>,b,B}; do bindkey -M $km $c select-bracketed; done
        done

        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        for key in '^[[A' '^[OA'; do bindkey -M viins $key up-line-or-beginning-search; done
        for key in '^[[B' '^[OB'; do bindkey -M viins $key down-line-or-beginning-search; done
        bindkey -M vicmd k up-line-or-beginning-search
        bindkey -M vicmd j down-line-or-beginning-search

        bindkey -M viins '^Y' autosuggest-accept
        bindkey -M vicmd / fzf-history-widget
      '')
    ];
  };

  programs.bash = {
    enable = true;
    historyFile = "${config.xdg.stateHome}/bash/history";
    historyControl = [ "ignoreboth" ];
  };

  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      keyseq-timeout = 150;
      show-mode-in-prompt = true;
      vi-ins-mode-string = "\\1\\e[6 q\\2";
      vi-cmd-mode-string = "\\1\\e[2 q\\2";
    };
    extraConfig = ''
      set keymap vi-insert
      "jk": vi-movement-mode
    '';
  };

  programs.dircolors.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    defaultCommand = "${fdCmd} --type f";
    defaultOptions = [ "--height=40%" "--layout=reverse" ];
    fileWidgetCommand = "${fdCmd} --type f";
    fileWidgetOptions = [ "--preview 'bat --color=always --style=numbers --line-range=:200 {}'" ];
    changeDirWidgetCommand = "${fdCmd} --type d";
    changeDirWidgetOptions = [ "--preview '${dirPreview} {}'" ];
    colors = {
      "bg+" = "#313244";
      fg = "#cdd6f4";
      "fg+" = "#cdd6f4";
      hl = "#f38ba8";
      "hl+" = "#f38ba8";
      header = "#f38ba8";
      info = "#cba6f7";
      prompt = "#cba6f7";
      pointer = "#f5e0dc";
      spinner = "#f5e0dc";
      marker = "#b4befe";
      border = "#6c7086";
      label = "#cdd6f4";
      selected-bg = "#45475a";
    };
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
  };

  programs.bat = {
    enable = true;
    config.theme = "Catppuccin Mocha";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = false;
    config.global.hide_env_diff = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "$username$hostname$container$directory"
        "$git_branch$git_state$git_status$nix_shell"
        "$cmd_duration$jobs$status$line_break$character"
      ];
      palette = "catppuccin_mocha";
      palettes.catppuccin_mocha = {
        crust = "#11111b";
        text = "#cdd6f4";
        overlay0 = "#6c7086";
        lavender = "#b4befe";
        blue = "#89b4fa";
        sky = "#89dceb";
        green = "#a6e3a1";
        yellow = "#f9e2af";
        peach = "#fab387";
        red = "#f38ba8";
        mauve = "#cba6f7";
      };
      directory = {
        style = "bold lavender";
        truncation_length = 3;
      };
      git_branch = {
        symbol = " ";
        style = "bold mauve";
        format = "[$symbol$branch]($style)";
      };
      git_status = {
        style = "yellow";
        format = "([$all_status$ahead_behind]($style)) ";
        modified = " !\${count}";
        staged = " +\${count}";
        untracked = " ?\${count}";
        deleted = " ✘\${count}";
        renamed = " »\${count}";
        stashed = " ≡\${count}";
        conflicted = " =\${count}";
        ahead = " ⇡\${count}";
        behind = " ⇣\${count}";
        diverged = " ⇡\${ahead_count}⇣\${behind_count}";
      };
      nix_shell = {
        symbol = "";
        style = "bold sky";
        format = "[$symbol nix]($style) ";
      };
      cmd_duration = {
        min_time = 2000;
        style = "peach";
        format = "[󱎫 $duration]($style) ";
        show_notifications = true;
        min_time_to_notify = 30000;
      };
      jobs = {
        symbol = "✦";
        number_threshold = 1;
        style = "blue";
        format = "[$symbol$number]($style) ";
      };
      status = {
        disabled = false;
        symbol = "✘ ";
        style = "red";
        format = "[$symbol$status]($style) ";
      };
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[ N ](bold fg:crust bg:blue) [❯](green)";
      };
    };
  };
}
