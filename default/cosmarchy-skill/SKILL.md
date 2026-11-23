---
name: cosmarchy
description: Control and reconfigure the Cosmarchy Linux operating system, including GNOME settings, extensions, window tiling, Dash to Dock, themes, flatpaks, and Btrfs snapshots.
---

# Cosmarchy OS Agent Skill

Use this skill whenever the user asks you to customize, reconfigure, automate, or troubleshoot their Cosmarchy Linux operating system.

Cosmarchy is an opinionated, developer-first Arch Linux distribution built with:
- **Desktop**: GNOME 51 (Wayland) + GDM
- **Dock**: Dash to Dock (Ubuntu-style left edge panel)
- **Tiling**: Tiling Shell zones, auto-placement off; `cosmarchy tiling <enable|disable|status>`
- **Theme Engine**: Unified themes (22 palettes with bundled 4K wallpapers: Tokyo Night, Catppuccin, Catppuccin Latte, Ethereal, Everforest, Flexoki Light, Gruvbox, Hackerman, Kanagawa, Last Horizon, Lumon, Lupine, Matte Black, Miasma, Nord, Osaka Jade, Retro 82, Ristretto, Rose Pine, Solitude, Vantablack, White)
- **Filesystem & Rollbacks**: Btrfs subvolumes (`@`, `@home`, `@snapshots`) + Snapper + Limine bootloader integration
- **Default Editor**: VS Code (`code`, text/plain and friends); `$EDITOR` is
  `code --wait` in a graphical session, `nano` in a TTY
- **Default Browser**: Brave Origin (`brave-origin` / `brave`, debloated, privacy-first)
- **App Store & Packages**: Pacman, Flatpak (Flathub), and Bazaar

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

## 1. Theme Management

Cosmarchy syncs desktop themes across GNOME (accent color, dark/light mode, wallpaper), GNOME Terminal, Neovim, and btop.

```bash
# List all 22 available themes
cosmarchy theme list

# Check active theme
cosmarchy theme current

# Apply any theme (18 Dark, 4 Light)
cosmarchy theme set "tokyo-night"
cosmarchy theme set "kanagawa"
cosmarchy theme set "hackerman"
cosmarchy theme set "flexoki-light"
cosmarchy theme set "catppuccin-latte"
```

To create a custom user theme:
1. Create directory: `~/.config/cosmarchy/themes/<my-theme>/`
2. Add `accent.txt` containing one of: `blue`, `teal`, `green`, `yellow`, `orange`, `red`, `pink`, `purple`, `slate`.
3. Add `backgrounds/<image.jpg|png|svg>`.
4. Add `alacritty.toml`, `neovim.lua`, and `btop.theme`.
5. Run: `cosmarchy theme set "<my-theme>"`

---

## 2. Desktop Environment (GNOME & Mutter)

Use `gsettings` or the `cosmarchy gnome` CLI helpers.

### Display Scaling & Fractional Scaling
```bash
# Enable Wayland fractional scaling in GNOME Settings -> Displays
cosmarchy gnome scaling enable

# Set font/text scaling factor directly
cosmarchy gnome scaling text 1.25
```

### Night Light
```bash
# Turn night light on or off
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500
```

### Power & Behavior
```bash
# Don't sleep while on AC power
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Center new windows
gsettings set org.gnome.mutter center-new-windows true
```

---

## 3. Ubuntu-Style Dock (Dash to Dock)

Configuration schema: `org.gnome.shell.extensions.dash-to-dock`

```bash
# Adjust icon size
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 44

# Enable/disable auto-hide (intellihide)
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true     # Persistent Ubuntu panel
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false   # Do not auto-hide

# Change dock position ('LEFT', 'BOTTOM', 'RIGHT', 'TOP')
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'

# Pin or reorder favorite applications in the dock
gsettings get org.gnome.shell favorite-apps
gsettings set org.gnome.shell favorite-apps "['brave-origin.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'code-oss.desktop', 'io.github.kolunmi.Bazaar.desktop', 'org.gnome.Settings.desktop']"
```

---

## 4. Tiling Management

Tiling is Tiling Shell with `enable-autotiling` off: hold Ctrl while dragging
to pick a zone, drag to the top for snap assist, `<Super><Shift>` + arrows to
throw a window into the next tile, `<Super>T` to cycle the zone layout.
`cosmarchy tiling disable` turns it off, `enable` turns it on and re-applies
Cosmarchy's settings.

Configuration schema: `org.gnome.shell.extensions.tilingshell`

Do not turn `enable-autotiling` on -- it places windows into fixed tiles
without resizing the ones already on screen. Cosmarchy has no tree tiling and
no directional focus; do not suggest Forge or another tiler alongside Tiling
Shell, two placers fight over every new window.

```bash
# Whether tiling is on, and whether the shell actually loaded the extension
cosmarchy tiling status

# Gaps, and the key that throws a window into the next tile
gsettings set org.gnome.shell.extensions.tilingshell inner-gaps 8
gsettings set org.gnome.shell.extensions.tilingshell outer-gaps 8
gsettings set org.gnome.shell.extensions.tilingshell move-window-left "['<Super><Shift>Left']"
```

---

## 5. Extensions Management

```bash
# List active extensions
cosmarchy gnome extensions list

# Enable or disable an extension
cosmarchy gnome extensions enable <uuid>
cosmarchy gnome extensions disable <uuid>

# Reset all extensions to Cosmarchy stock defaults
cosmarchy gnome extensions reset
```

---

## 6. Keyboard Shortcuts

Inspect active shortcuts:
```bash
cosmarchy gnome hotkeys
```

To add a new custom shortcut, register under `/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/`:
```bash
# Example: Bind Super+N to open the editor
BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | sed "s/]/, '$BINDING_PATH\/']/ \")"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH/ name 'Editor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH/ command 'code'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH/ binding '<Super>n'
```

---

## 7. Package & Flatpak Management

```bash
# Install Arch package via pacman
sudo pacman -S --needed <package>

# Search or install Flatpaks from Flathub
flatpak search <app>
flatpak install -y flathub <app-id>

# Launch Bazaar Flatpak software center
flatpak run io.github.kolunmi.Bazaar
```

---

## 8. Rollback Snapshots

```bash
# List all current Btrfs snapshots
cosmarchy snapshot list

# Create a snapshot before making system modifications
cosmarchy snapshot create "Pre-refactor snapshot"

# Make snapshot 12 the system from the next boot on
cosmarchy snapshot restore 12 --yes
```

---

## 9. Web Applications (`cosmarchy webapp`)

Turn any web URL into an isolated desktop application launcher with its own profile and Dash to Dock support:

```bash
# Add a web application
cosmarchy webapp add "Claude" "https://claude.ai"
cosmarchy webapp add "ChatGPT" "https://chatgpt.com"
cosmarchy webapp add "Linear" "https://linear.app"

# List web apps
cosmarchy webapp list

# Remove a web app
cosmarchy webapp remove "Claude"
```

---

## 10. Desktop Reminders (`cosmarchy reminder`)

Schedule desktop notifications with chime alerts:

```bash
# Duration-based reminders
cosmarchy reminder 25m "Pomodoro break"
cosmarchy reminder 1h30m "Review deployment logs"

# Clock-based reminders
cosmarchy reminder 17:30 "Team Standup"

# List or cancel active reminders
cosmarchy reminder list
cosmarchy reminder cancel <reminder-id>
```

---

## 11. Voxtype AI Speech-to-Text (`cosmarchy voxtype`)

System-wide speech-to-text powered by local offline Whisper models:

```bash
# Toggle recording (also bound to Super+D)
cosmarchy voxtype toggle

# Manual controls
cosmarchy voxtype start
cosmarchy voxtype stop
cosmarchy voxtype status
```

---

## 12. Windows apps (`cosmarchy windows`)

WinBoat runs Windows in a Docker container and opens its applications as
desktop windows. It is opt-in; install it only when the user asks:

```bash
cosmarchy windows install   # winboat-bin from the AUR, else the release AppImage
cosmarchy windows status    # KVM, Docker, docker group, FreeRDP, and whether it is installed
cosmarchy windows           # start WinBoat
```

---

## 13. Event Hooks (`~/.config/cosmarchy/hooks/`)

Subscribe to Cosmarchy system events:
- `on-theme-change <theme-name>`: Triggered when theme is switched.
- `on-snapshot <description>`: Triggered after Btrfs snapshot creation.
- `on-update <pre|post>`: Triggered before/after system updates.
- `on-webapp-add <name> <url>`: Triggered when a new web app is added.

Trigger hooks manually:
```bash
cosmarchy hook on-theme-change "tokyo-night"
```
