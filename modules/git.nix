{ ... }:

{
  programs.git = {
    enable = true;
    userName = "Gonzalo G. Fernandez";
    userEmail = "fernandez.gfg@gmail.com";
    ignores = [ "**/.claude/settings.local.json" ];
    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "main";
      status.branch = true;
      status.showStash = true;
      url."git@github.com:".insteadOf = "gh:";
    };
  };
}
