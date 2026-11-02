{ config, lib, pkgs, ... }:

let
  internal = "eDP-1,preferred,auto,1.333333";
  hyprctl = "${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl";
in
{
  imports = [ ../home.nix ];

  home.username = "dell-1";
  home.homeDirectory = "/home/dell-1";

  programs.git.settings.user.email = "gonzalo.fernandez@nio-robotics.com";

  # 2560x1600 has no clean 1.5 divisor; 1.333333 gives a 1920x1200 workspace.
  wayland.windowManager.hyprland.settings.monitor = [ internal ];

  # kitty's font_size is the last one in the file; this overrides config/kitty/kitty.conf.
  programs.kitty.extraConfig = lib.mkAfter "font_size 9.0";

  programs.noctalia.settings.widget.network.show_label = true;

  # Lid closed only stays awake when docked (logind), so the panel can go dark safely.
  wayland.windowManager.hyprland.settings.bindl = [
    ", switch:on:Lid Switch, exec, ${hyprctl} keyword monitor \"eDP-1,disable\""
    ", switch:off:Lid Switch, exec, ${hyprctl} keyword monitor \"${internal}\""
  ];
  # Reloads and logins re-enable every monitor, so re-apply a closed lid on each config load.
  wayland.windowManager.hyprland.settings.exec = [
    "${pkgs.gnugrep}/bin/grep -q closed /proc/acpi/button/lid/*/state && ${hyprctl} keyword monitor eDP-1,disable"
  ];

  # The external outputs hang off the NVIDIA GPU. Must match the host driver
  # exactly (cat /sys/module/nvidia/version); bump together with apt, see README.md.
  targets.genericLinux.gpu.nvidia = {
    enable = true;
    version = "580.178.04";
    sha256 = "sha256-WXWobuRb/8tib1GuM9EWmxCBhqLqR61lHnLxP6S21vk=";
  };
}
