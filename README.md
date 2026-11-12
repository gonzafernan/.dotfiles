# My dotfiles!

Home-manager configuration for two Ubuntu machines, `personal` and `work`.

```sh
nix run home-manager -- switch --flake ".?submodules=1#personal"   # or #work
```

`submodules=1` is required: `config/nvim` is a git submodule, which flakes skip by default.

## Layout

- `flake.nix` — inputs and the host profiles. `nixpkgs-unstable` is for apps that
  need to stay current (Chrome, Obsidian, Claude Code, ...).
- `hosts/` — per-machine settings
- `home.nix` — modules shared by every host
- `modules/` — one module per tool or topic
- `config/` — the tools' own config files, used as-is
- `system/` — files installed by hand with sudo (see below)

CI evaluates both hosts and updates `flake.lock` twice a month.

## Shell

kitty and tmux start zsh; bash stays the login shell. See `modules/shell.nix`:
vi mode (`jk` for normal mode), fzf for history, files and completion, and a starship prompt.

Tools are installed here or not at all:

- needed by one project: that project's `flake.nix` plus an `.envrc` with `use flake` (direnv)
- needed once: `nix run nixpkgs#<tool>`

## One-time system setup

Things a per-user home-manager can't reach on a non-NixOS distro. Redo them on a fresh install.

### GPU drivers

Links Nix's Mesa into `/run/opengl-driver` for Nix-built GL apps. Rerun whenever
activation warns that the drivers changed:

```sh
sudo $(readlink -f ~/.nix-profile/bin/non-nixos-gpu-setup)
```

`work` also needs NVIDIA's libraries, which must match the kernel driver exactly, so the driver is held:

```sh
sudo apt-mark hold nvidia-driver-580-open linux-modules-nvidia-580-open-generic
```

To update it:

1. Unhold both packages, upgrade and reboot.
2. In `hosts/work.nix`, set `version` to the output of `cat /sys/module/nvidia/version`
   and `sha256` to the output of
   `nix store prefetch-file https://download.nvidia.com/XFree86/Linux-x86_64/<version>/NVIDIA-Linux-x86_64-<version>.run`.
3. Switch, rerun the setup command above, and hold both packages again.

### Chrome and Electron sandbox

Ubuntu only allows the user namespaces their sandboxes need for binaries with an
AppArmor profile:

```sh
for p in nix-google-chrome nix-electron; do
  sudo cp system/apparmor.d/$p /etc/apparmor.d/
  sudo apparmor_parser -r /etc/apparmor.d/$p
done
```

Trade-off: anything running as this user can create a matching store path and
regain user namespaces.

### Hyprland

```sh
sudo cp system/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/
sudo usermod -aG render "$USER"   # GBM/DRM access; log out and back in afterwards
```

### Lock screen

Nix's PAM can't parse Ubuntu's `/etc/pam.d`, and it looks for `unix_chkpwd` at a
NixOS-only path. Without this, the lock screen rejects every password:

```sh
sudo cp system/pam.d/noctalia /etc/pam.d/noctalia
sudo cp system/tmpfiles.d/nix-pam-wrappers.conf /etc/tmpfiles.d/
sudo systemd-tmpfiles --create /etc/tmpfiles.d/nix-pam-wrappers.conf
```

If you get stuck at the lock screen: switch to a TTY (Ctrl+Alt+F3), log in, then run
`loginctl list-sessions` and `loginctl unlock-session <id>`.
