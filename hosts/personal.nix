{ ... }:

{
  imports = [
    ../home.nix
    ../modules/hdl.nix
    ../modules/f3d.nix
  ];

  home.username = "ggf";
  home.homeDirectory = "/home/ggf";
}
