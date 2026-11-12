{ lib, ... }:

{
  programs.git = {
    enable = true;
    ignores = [ "**/.claude/settings.local.json" ];
    settings = {
      user.name = lib.mkDefault "Gonzalo G. Fernandez";
      user.email = lib.mkDefault "fernandez.gfg@gmail.com";
      core.editor = "nvim";
      init.defaultBranch = "main";
      push.recurseSubmodules = "check";
      status.branch = true;
      status.showStash = true;
      url."git@github.com:".insteadOf = "gh:";
      alias.adog = "log --all --decorate --graph --oneline";
    };
  };
}
