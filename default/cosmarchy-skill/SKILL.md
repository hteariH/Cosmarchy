---
name: cosmarchy
description: Control and reconfigure the Cosmarchy Linux operating system, including COSMIC desktop RON configs, auto-tiling, shortcuts, packages, Flatpaks, WinBoat, and Btrfs snapshots.
---

# Cosmarchy OS Agent Skill

Use this skill whenever the user asks you to customize, reconfigure, automate, or troubleshoot their Cosmarchy Linux operating system.

Cosmarchy is an opinionated, developer-first Arch Linux distribution built with:
- **Desktop**: Stock COSMIC 1.11 (Wayland) + `greetd` (`cosmic-greeter`)
- **Native Apps**: `cosmic-terminal` (`cosmic-term`), `cosmic-files`, `cosmic-text-editor`, `cosmic-player`, `cosmic-store`
- **Tiling**: COSMIC built-in auto-tiling (`autotile = true`, `autotile_behavior = PerWorkspace`); `cosmarchy tiling <enable|disable|toggle|status>`
- **Filesystem & Rollbacks**: Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`, `@var_cache`) + Snapper + Limine bootloader integration (fixed COSMIC Dark palette)
- **Default Editor**: VS Code (`code`, graphical default); `$EDITOR` is `code --wait` in a graphical session, `nano` in a TTY; Neovim ships with stock LazyVim
- **Default Browser**: Brave Origin (`brave-origin` / `brave`, debloated, privacy-first)
- **Phone Sync**: KDE Connect (`kdeconnect`, ufw ports 1714-1764 allowed)
- **App Store & Packages**: Pacman, Flatpak (Flathub), COSMIC Store, and Bazaar

---

## Safety Protocol for AI Agents

> [!IMPORTANT]
> **Before performing any disruptive system, package, or configuration change:**
> Run a Btrfs rollback snapshot:
> ```bash
> cosmarchy snapshot create "Before agent change: <description of change>"
> ```
> Every snapshot appears in the Limine menu, and `cosmarchy snapshot restore <n>` makes one the system.

---

## 1. COSMIC Configuration (`~/.config/cosmic/`)

COSMIC stores settings as plain RON files, one key per file under `~/.config/cosmic/<component-id>/v1/<key>`, falling back to `/usr/share/cosmic/<component-id>/v1/<key>` (never write under `/usr/share/cosmic/`).

Key files managed by Cosmarchy:
- `~/.config/cosmic/com.system76.CosmicComp/v1/autotile` (`true` / `false`)
- `~/.config/cosmic/com.system76.CosmicComp/v1/autotile_behavior` (`PerWorkspace` / `Global`)
- `~/.config/cosmic/com.system76.CosmicComp/v1/xkb_config` (XKB layout/variant struct)
- `~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom` (map of custom bindings)
- `~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions` (`Terminal`, `WebBrowser`)

Write changes atomically (write to temp file in the same directory, then `mv`), or use `cosmarchy_cosmic_write` from `~/.local/share/cosmarchy/install/helpers/cosmic.sh`.

---

## 2. Tiling Management

COSMIC has built-in compositor auto-tiling (`cosmic-comp` watches the config file live):

```bash
cosmarchy tiling status    # show autotile and autotile_behavior
cosmarchy tiling enable    # autotile = true
cosmarchy tiling disable   # autotile = false
cosmarchy tiling toggle    # flip on/off
```

Key COSMIC tiling shortcuts:
- `Super + Y`: toggle auto-tiling for the active workspace
- `Super + G`: float / tile the focused window
- `Super + O`: toggle tiling orientation
- `Super + S`: toggle window stacking
- `Super + H/J/K/L` (or arrows): directional focus
- `Super + Shift + H/J/K/L` (or arrows): move window
- `Super + R`: resize mode

---

## 3. Keyboard Shortcuts

Inspect active shortcuts (reads COSMIC `defaults` and user `custom` RON files):
```bash
cosmarchy keybindings          # interactive filter (Super + Alt + /)
cosmarchy keybindings --list   # plain list
cosmarchy keybindings reset    # re-deploy Cosmarchy default custom + system_actions
```

COSMIC defaults win; never override a key present in `/usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults` unless the user explicitly asks. Check `journalctl --user -b | grep -i "shortcuts custom config error"` after editing RON shortcut files.

---

## 4. Package & Flatpak Management

```bash
# Install Arch package via pacman
sudo pacman -S --needed <package>

# Search or install Flatpaks from Flathub
flatpak search <app>
flatpak install -y flathub <app-id>

# Launch COSMIC Store or Bazaar
cosmic-store
flatpak run io.github.kolunmi.Bazaar
```

---

## 5. Rollback Snapshots & Boot Menu

```bash
cosmarchy snapshot list
cosmarchy snapshot create "Pre-refactor snapshot"
cosmarchy snapshot restore 12 --yes
cosmarchy boot update          # regenerate /boot/limine.conf after editing /etc/kernel/cmdline
```

---

## 6. Web Applications (`cosmarchy webapp`)

```bash
cosmarchy webapp add "Claude" "https://claude.ai"
cosmarchy webapp list
cosmarchy webapp remove "Claude"
```

---

## 7. Desktop Reminders (`cosmarchy reminder`)

```bash
cosmarchy reminder 25m "Pomodoro break"
cosmarchy reminder 17:30 "Team Standup"
cosmarchy reminder list
cosmarchy reminder cancel <reminder-id>
```

---

## 8. Voxtype AI Speech-to-Text (`cosmarchy voxtype`)

```bash
cosmarchy voxtype toggle       # also bound to Super + D
cosmarchy voxtype status
```

---

## 9. Windows Apps (`cosmarchy windows`)

WinBoat runs Windows in a Docker container and opens its applications as desktop windows. Opt-in only:

```bash
cosmarchy windows install      # winboat-bin from AUR, else release AppImage
cosmarchy windows status       # KVM, Docker, docker group, FreeRDP
cosmarchy windows              # start WinBoat
```

---

## 10. Gaming & Asus Hardware

```bash
cosmarchy gaming install       # Steam, Proton-GE, Wine, Lutris, gamescope, GameMode, MangoHud
cosmarchy gaming status
cosmarchy asus status          # ROG/TUF laptop controls (asusctl / supergfxctl)
```

---

## 11. Event Hooks (`~/.config/cosmarchy/hooks/`)

Available hooks:
- `on-snapshot <description>`: Triggered after Btrfs snapshot creation.
- `on-update <pre|post>`: Triggered before/after system updates.
- `on-webapp-add <name> <url>`: Triggered when a web app is added.
- `on-webapp-remove <name>`: Triggered when a web app is removed.

```bash
cosmarchy hook list
```
