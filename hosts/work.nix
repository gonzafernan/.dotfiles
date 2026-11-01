{ ... }:

{
  imports = [ ../home.nix ];

  home.username = "dell-1";
  home.homeDirectory = "/home/dell-1";

  programs.git.settings.user.email = "gonzalo.fernandez@nio-robotics.com";

  # 2560x1600 has no clean 1.5 divisor; 1.333333 gives a 1920x1200 workspace.
  wayland.windowManager.hyprland.settings.monitor = [ "eDP-1,preferred,auto,1.333333" ];

  # The external outputs hang off the NVIDIA GPU. Must match the host driver
  # exactly (cat /sys/module/nvidia/version); bump together with apt, see README.md.
  targets.genericLinux.gpu.nvidia = {
    enable = true;
    version = "580.178.04";
    sha256 = "sha256-WXWobuRb/8tib1GuM9EWmxCBhqLqR61lHnLxP6S21vk=";
  };
}
