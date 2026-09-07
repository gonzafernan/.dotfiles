# My dotfiles!

## Environment setup

Everything is installed and configured via Nix (home-manager):

```sh
nix run home-manager -- switch --flake ".?submodules=1#ggf"
```

(the `submodules=1` is required — this repo has git submodules, and Nix's flake
git fetcher excludes submodule content by default)

## Tools tracked

- Neovim
- tmux
- kitty
- yazi
- git
- Obsidian (config only — the app itself is a manual install at `/opt/obsidian`,
  not managed by Nix)
- Hyprland (see below)
- Google Chrome — installed from `pkgsUnstable` (a second `nixpkgs-unstable`
  flake input, see `flake.nix`), not the main `nixpkgs-24.11` pin: nixpkgs'
  `google-chrome` derivation fetches one specific `.deb` by URL, and Google
  routinely removes old versions from its download mirror, so a stable pin
  404s within weeks. `nixpkgs-unstable` tracks the current version closely
  enough to actually build. Wrapped with `--force-device-scale-factor=1.5` for
  this machine's ~240 PPI panel (see `hyprland.nix`'s `NIXOS_OZONE_WL`/
  `XDG_DATA_DIRS` comments for the rest of what that needed).

## Hyprland on non-NixOS: required manual system setup

Hyprland itself and its whole ecosystem (waybar, mako, hyprlock, hyprpaper,
hypridle, ...) are fully declared in `hyprland.nix`. But a few things live outside
what a per-user home-manager install can reach — system paths and group
membership — and have no Nix-managed equivalent on a non-NixOS distro. These are
one-time steps to redo on a fresh machine (or after a reinstall):

1. **Render group membership** (needed for Hyprland's GBM/DRM access — without
   it, Hyprland crashes on startup with `CDRMRenderer: fail, no gbm support`):
   ```sh
   sudo usermod -aG render "$USER"
   ```
   Requires a full logout/login (not just re-activating home-manager) to take
   effect.

2. **GDM session entry**, so Hyprland is selectable at the login screen:
   ```sh
   sudo cp hyprland/system/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/
   ```

3. **hyprlock's PAM setup.** Nix's own PAM library (linked into Nix-built
   hyprlock) can't parse Debian/Ubuntu's `@include` directive used throughout
   `/etc/pam.d/*`, so without its own config hyprlock fails every login attempt
   with `pam_authenticate failed` — **regardless of the password**, since the
   config never even parses:
   ```sh
   sudo cp hyprland/system/pam.d/hyprlock /etc/pam.d/hyprlock
   ```
   Separately, Nix's `pam_unix.so` has `/run/wrappers/bin/unix_chkpwd` hardcoded
   as the helper it execs to check the password against `/etc/shadow` — a
   NixOS-only path (created there by NixOS's setuid-wrapper mechanism). This
   redirects it to Ubuntu's own working `unix_chkpwd`. Uses `tmpfiles.d` (not a
   one-off symlink) because `/run` is a tmpfs wiped on every reboot:
   ```sh
   sudo cp hyprland/system/tmpfiles.d/nix-pam-wrappers.conf /etc/tmpfiles.d/
   sudo systemd-tmpfiles --create /etc/tmpfiles.d/nix-pam-wrappers.conf
   ```

**If hyprlock ever gets stuck again** (PAM misconfigured, screen locked, password
not accepted): switch to a TTY (Ctrl+Alt+F3), log in there (unaffected — it uses
the system's own PAM stack, not Nix's), and run `pkill hyprlock` to force it closed
without needing to authenticate.
