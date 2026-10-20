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
  enough to actually build. Needs a one-time AppArmor profile for its sandbox
  (see below); scales itself automatically via `hyprland.nix`'s `monitor`
  scale and `NIXOS_OZONE_WL`, no per-app scale flag needed.
- Vivado (Xilinx Design Suite) — config only, same as Obsidian: a manual
  install at `/tools/Xilinx/Vivado/2024.2` (proprietary, licensed, not in
  nixpkgs, not something we'd package ourselves), not managed by Nix at all.
  Only its `.desktop` launcher entry is tracked (`home.nix`), so the launcher can find
  it — bump the version number there if Vivado is ever upgraded.

## Chrome sandbox: required manual system setup

Ubuntu blocks unprivileged user namespaces unless an AppArmor profile allows
them, and Chrome's sandbox needs them. Ubuntu's own profile only covers
`/opt/google/chrome/chrome`, so the Nix build gets an equivalent one matching
its store path (without it Chrome refuses to start):

```sh
sudo cp system/apparmor.d/nix-google-chrome /etc/apparmor.d/
sudo apparmor_parser -r /etc/apparmor.d/nix-google-chrome
```

Trade-off: anything running as this user can create a store path matching the
profile's glob and regain user namespaces, which the restriction exists to
deny. Accepted here in exchange for Chrome's renderer sandbox.

## Hyprland on non-NixOS: required manual system setup

Hyprland itself and its whole ecosystem (the noctalia shell — bar, notifications,
lock screen, idle, wallpaper, launcher, ...) are fully declared in `hyprland.nix`. But a few things live outside
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

3. **noctalia's lock screen PAM setup.** Nix's own PAM library (linked into
   Nix-built noctalia) can't parse Debian/Ubuntu's `@include` directive used
   throughout `/etc/pam.d/*`, so without its own config the lock screen fails
   every unlock attempt — **regardless of the password**, since the config never
   even parses. Upstream hardcodes the `login` service (which TTY login also
   uses, so it must stay untouched); `flake.nix` patches it to `noctalia`:
   ```sh
   sudo cp hyprland/system/pam.d/noctalia /etc/pam.d/noctalia
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

**If the lock screen ever gets stuck** (PAM misconfigured, screen locked, password
not accepted): switch to a TTY (Ctrl+Alt+F3), log in there (unaffected — it uses
the system's own PAM stack, not Nix's), find the Hyprland session with
`loginctl list-sessions` and run `loginctl unlock-session <id>` — noctalia unlocks
on logind's Unlock signal without needing to authenticate.
