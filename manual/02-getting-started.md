# Getting Started

## Installing

Boot the ISO; the installer starts on its own on the first console.

1. **Disk.** Choose the disk. All of it is used and erased; disks under
   20 GiB are refused.
2. **Form.** Keyboard layout first — the console switches to it, so the
   passwords that follow are typed the way you will type them later, and your
   chosen layout is written straight into COSMIC's `xkb_config`. Then your
   name, user name, password, the computer's name and the timezone (type to
   search). Encryption is optional; the disk password can be the same as your
   own.
3. **Summary.** Check it. *Edit* goes back to the form with your answers kept
   for the keyboard layout, names, computer name and timezone; the passwords
   and the encryption choice are asked again. Nothing is written until you
   choose *Install*.
4. **Progress.** Seven stages. If one fails, the screen shows the end of the
   log and offers the full log, a shell, or power off. The log is
   `/var/log/cosmarchy-installer.log`, copied to the installed system.

## First login

On an interactive install, `cosmic-initial-setup` runs once at first login to
configure language, keyboard, timezone, Wi-Fi, accessibility, appearance, and
panel layout. Cosmarchy does not override what it asks.

## The first five minutes

- Press `Super + Alt + Space` for **Cosmarchy actions** in COSMIC Launcher
  (prefilled with `c `): tiling, snapshots, updates, web apps, screen capture,
  gaming, COSMIC Settings, and power. (`cosmarchy menu` provides the same flat
  list in a TTY or over SSH.)
- Press `Super + Alt + /` for **Keybindings** in COSMIC Launcher (`c key `),
  read directly from your active COSMIC RON files.
- Press `Super + Alt + M` for this **Manual** in COSMIC Launcher (`c man `).
- Press `Super + Return` (or COSMIC's `Super + T`) for **COSMIC Terminal**.
- Press `Super` alone for **COSMIC Launcher** (you can also type `c `, `c key `,
  or `c man ` from there).
- Press `Super + Y` to toggle auto-tiling on the current workspace.

## Preinstalled apps & phone sync

Cosmarchy ships Brave Origin (default browser), Chromium, VS Code, Neovim
(LazyVim), OBS Studio, LibreOffice, Obsidian, Telegram, Discord, Spotify
(`spotify-launcher`), `mise`, Claude Code, Flatpak (Bazaar + LocalSend), and
**KDE Connect** (`kdeconnect`, with ufw ports `1714-1764` pre-allowed).
