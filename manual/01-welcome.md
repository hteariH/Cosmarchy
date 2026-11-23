# Welcome to Cosmarchy

Cosmarchy is Omarchy's tooling and Arch base paired with the **COSMIC 1.11**
desktop on Wayland (`greetd` + `cosmic-greeter`). Same rolling release, same
bootable Btrfs snapshots, same opinionated developer stack — with COSMIC's
native compositor and applications underneath.

## What that means in practice

You get stock COSMIC's Wayland polish, built-in per-workspace auto-tiling,
native Rust applications (`cosmic-terminal`, `cosmic-files`,
`cosmic-text-editor`, `cosmic-player`, `cosmic-store`), fractional scaling, and
first-login configuration via `cosmic-initial-setup`. On top of that sits the
Cosmarchy layer: bootable Btrfs rollbacks in Limine, a CLI command center, web
apps, local AI dictation, WinBoat opt-in Windows support, gaming and laptop
profiles, and KDE Connect.

## Design principles

- **Stock COSMIC appearance**: Cosmarchy deploys behaviour-only RON config
  under `~/.config/cosmic/` and leaves appearance, themes, and wallpapers to
  COSMIC Settings and `cosmic-initial-setup`.
- **COSMIC defaults win**: Cosmarchy never shadows a built-in COSMIC shortcut.
  Every Cosmarchy keybinding lives on a key COSMIC leaves free.
- **Plain files, no hidden state**: COSMIC configuration is plain RON files
  written directly during installation.

## Where to go next

- `cosmarchy manual 02` - getting started
- `cosmarchy manual 03` - keybindings
- `cosmarchy manual 04` - auto-tiling
- `cosmarchy keybindings` - what is bound right now
