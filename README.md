# Cosmarchy Linux

<p align="center">
  <img src="assets/logo.svg" alt="Cosmarchy" width="120">
</p>

<p align="center">
  <a href="https://cosmarchy.pages.dev"><img src="https://img.shields.io/badge/Website-cosmarchy.pages.dev-49bac8?style=for-the-badge&logo=cloudflarepages&logoColor=white" alt="Website"></a>
  <a href="https://github.com/hteariH/Cosmarchy/releases"><img src="https://img.shields.io/github/v/release/hteariH/Cosmarchy?style=for-the-badge&color=49bac8&logo=github" alt="Release"></a>
  <img src="https://img.shields.io/badge/Arch%20Linux-Rolling-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux">
  <img src="https://img.shields.io/badge/COSMIC-1.11-49bac8?style=for-the-badge&logo=linux&logoColor=white" alt="COSMIC 1.11">
  <img src="https://img.shields.io/badge/Wayland-Native-7cb987?style=for-the-badge&logo=wayland&logoColor=white" alt="Wayland">
  <img src="https://img.shields.io/badge/Btrfs-Snapper%20Rollbacks-6296be?style=for-the-badge&logo=linux&logoColor=white" alt="Btrfs">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-ddc74c?style=for-the-badge" alt="License"></a>
</p>

> **The Power of Arch Linux and Omarchy's Developer Tooling Meets the COSMIC Desktop.**

Cosmarchy is an opinionated, developer-first Linux distribution built on **Arch Linux**. It pairs the rolling base, bootable Btrfs + Snapper rollbacks, hardware profiles, and CLI developer stack derived from **Omarchy** with the authentic stock **COSMIC 1.11** desktop environment and **greetd** (`cosmic-greeter`) on Wayland.

---

## Highlights & Features

- **Authentic Stock COSMIC 1.11 + `greetd`**: Full COSMIC Wayland desktop with `cosmic-initial-setup` on first login (language, keyboard, timezone, Wi-Fi, accessibility, appearance, panel layout) and native COSMIC apps (`cosmic-terminal`, `cosmic-files`, `cosmic-text-editor`, `cosmic-player`, `cosmic-store`).
- **Built-in Auto-Tiling (Per Workspace)**: COSMIC's native auto-tiling is enabled out of the box with per-workspace behavior (`Super + Y` to toggle, `Super + G` to float a window, `Super + O` for orientation, `Super + S` for stacking, or `cosmarchy tiling <enable|disable|toggle|status>`).
- **Non-Conflicting Shortcuts**: All COSMIC default shortcuts remain intact. Cosmarchy adds its own bindings strictly on free keys (`Super + Return`, `Super + E`, `Super + D`, `Ctrl + Print`, `Super + Alt + Space`, `Super + Alt + /`, `Super + Alt + M`).
- **COSMIC Launcher Integration (`Super + Alt + Space`, `c `)**: Native `pop-launcher` plugin exposing Cosmarchy actions (`c `), active keybindings (`c key ` on `Super + Alt + /`), and local manual pages (`c man ` on `Super + Alt + M`) directly inside COSMIC Launcher. Backed by a single `launcher/actions.tsv` catalog, with a flat `gum filter` fallback (`cosmarchy menu`) for TTY and SSH sessions.
- **Voxtype (System-Wide Local AI Dictation)**: Offline speech-to-text dictation on `Super + D` powered by local `whisper-cpp` (`whisper-cli`) and `ydotool` — zero cloud fees and zero telemetry.
- **Web App Generator (`cosmarchy webapp`)**: Turn web tools (Claude, ChatGPT, Linear, Notion) into isolated desktop apps with separate profiles, auto-fetched favicons, and desktop entries visible in COSMIC Launcher and App Library.
- **Windows Apps, Opt-In (`cosmarchy windows install`)**: [WinBoat](https://www.winboat.app) runs Windows in a Docker container and opens its applications as ordinary desktop windows over FreeRDP. Installed only when you ask (AUR `winboat-bin` or checksum-pinned release AppImage).
- **Desktop Reminders & Alarms (`cosmarchy reminder`)**: Instant notification alarms with chime audio cues for pomodoro breaks, standups, or deploy checks.
- **AI Agent OS Control Layer & Lifecycle Hooks**: Pre-installed agent skill (`~/.claude/skills/cosmarchy/SKILL.md` & friends) and lifecycle hooks (`~/.config/cosmarchy/hooks/`).
- **Bootable Btrfs Snapshots + Limine**: `snap-pac` takes pre/post snapshots around every pacman transaction. Every snapshot appears in the COSMIC Dark-styled Limine boot menu with its matching kernel; boot one read-only in a tmpfs overlay and promote it with `cosmarchy snapshot restore`.
- **Fast Shutdown Tuning**: Systemd stop timeouts reduced from 90s to 10s.
- **Default Privacy Browser (Brave Origin)**: Pre-configured as the default browser (debloated of crypto, AI, rewards, and telemetry), with Chromium installed as fallback.
- **VS Code as the Default Editor**: Preinstalled from Arch's `extra` repo as the graphical default (`$EDITOR` is `code --wait` in a graphical session, `nano` in a TTY or over SSH). Neovim (stock LazyVim starter) is also installed.
- **One-Command Gaming Stack**: `cosmarchy gaming install` sets up Steam, Proton-GE, Wine, Lutris, Faugus Launcher, gamescope, GameMode, and MangoHud, matching the 32-bit Vulkan driver to your GPU.
- **Desktop Apps Preinstalled**: Telegram, Discord, Chromium, OBS Studio, LibreOffice, Obsidian, Spotify (via `spotify-launcher`), `mise`, and Claude Code.
- **KDE Connect (`kdeconnect`)**: Phone notifications, file sharing, clipboard, and media control out of the box, with ports `1714-1764` TCP/UDP pre-allowed in `ufw`.
- **Flatpak & Bazaar**: Flathub configured with Bazaar and LocalSend preinstalled alongside `cosmic-store`.
- **Hardware Profiles**: Auto-detected at install time — **Asus ROG/TUF** (`asusctl`, `rog-control-center`, `supergfxctl` on hybrid NVIDIA), **Framework 13/16** (RGB udev rules and AMD microphone profile), **Apple T2**, **NVIDIA** (DRM modesetting & suspend services), and **Intel** media/Vulkan drivers.

---

## Desktop Workflow & Keyboard Shortcuts

Cosmarchy keeps COSMIC's defaults untouched and adds seven shortcuts on keys COSMIC leaves free:

### Cosmarchy Shortcuts

| Shortcut | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Launch **COSMIC Terminal** (`cosmic-term`) |
| <kbd>Super</kbd> + <kbd>E</kbd> | Open **COSMIC Files** (`cosmic-files`) |
| <kbd>Super</kbd> + <kbd>D</kbd> | **Voxtype**: Toggle local AI speech-to-text dictation |
| <kbd>Ctrl</kbd> + <kbd>Print</kbd> | Region screenshot (`grim` + `slurp`) into **Satty** annotator |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>Space</kbd> | **Cosmarchy actions** in COSMIC Launcher (`cosmic-launcher input "c "`) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>/</kbd> | **Keybindings** in COSMIC Launcher (`cosmic-launcher input "c key "`) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>M</kbd> | **Local manual** in COSMIC Launcher (`cosmic-launcher input "c man "`) |

### Key COSMIC Defaults

| Shortcut | Action |
| :--- | :--- |
| <kbd>Super</kbd> | **COSMIC Launcher** |
| <kbd>Super</kbd> + <kbd>A</kbd> | **COSMIC App Library** |
| <kbd>Super</kbd> + <kbd>W</kbd> | Workspace overview |
| <kbd>Super</kbd> + <kbd>B</kbd> | Default web browser (**Brave Origin** via `system_actions`) |
| <kbd>Super</kbd> + <kbd>T</kbd> | Default terminal (**COSMIC Terminal**) |
| <kbd>Super</kbd> + <kbd>F</kbd> | Home folder |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close focused window |
| <kbd>Super</kbd> + <kbd>Y</kbd> | Toggle auto-tiling for the active workspace |
| <kbd>Super</kbd> + <kbd>G</kbd> | Float / tile the focused window |
| <kbd>Super</kbd> + <kbd>O</kbd> / <kbd>S</kbd> | Toggle tiling orientation / window stacking |
| <kbd>Super</kbd> + <kbd>H/J/K/L</kbd> or arrows | Focus window directionally |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>H/J/K/L</kbd> or arrows | Move window directionally |
| <kbd>Super</kbd> + <kbd>1</kbd> – <kbd>9</kbd> | Switch workspace 1–9 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> – <kbd>9</kbd> | Move window to workspace 1–9 |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Switch keyboard input source |
| <kbd>Super</kbd> + <kbd>Escape</kbd> | Lock screen |
| <kbd>Print</kbd> | **COSMIC Screenshot** |

---

## Installation

### Method 1: Bootable Installation ISO (Recommended)

1. Download the latest `cosmarchy-linux-*.iso` from [Releases](https://github.com/hteariH/Cosmarchy/releases).
2. Flash to a USB drive using `dd`, `balenaEtcher`, or `caligula`:
   ```bash
   sudo dd if=cosmarchy-linux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
3. Boot your system in **UEFI or BIOS mode** with Secure Boot disabled.
4. The gum installer starts on TTY1: pick a disk, fill in the form (keyboard layout, user, password, computer name, timezone, optional LUKS2 encryption), confirm the summary, and watch seven stages run. It creates Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`, `@var_cache`), installs Limine for UEFI and BIOS, deploys COSMIC + `cosmic-greeter` (with your chosen keyboard layout in `xkb_config`), and records snapshot 1.
5. On first login, `cosmic-initial-setup` walks you through appearance, panel layout, Wi-Fi, and accessibility.

### Method 2: Quick Install Over Clean Arch Linux

If you already have a minimal Arch Linux installation:

```bash
curl -fsSL https://cosmarchy.pages.dev/install | bash
```

---

## Master CLI Dispatcher (`cosmarchy`)

Control the desktop and OS layer with the `cosmarchy` CLI:

### Window Tiling

COSMIC's compositor (`cosmic-comp`) includes built-in auto-tiling configured per workspace (`autotile = true`, `autotile_behavior = PerWorkspace`).

```bash
cosmarchy tiling status    # show current autotile state and behavior
cosmarchy tiling enable    # turn automatic tiling on
cosmarchy tiling disable   # turn automatic tiling off
cosmarchy tiling toggle    # flip automatic tiling on/off
```

### The Manual

```bash
cosmarchy manual                    # interactive gum browser (or Super + Alt + M / `c man ` in launcher)
cosmarchy manual 04                 # open a page by number
cosmarchy manual tiling             # open a page by name
cosmarchy manual --list             # list all 15 pages
cosmarchy manual --grep whisper     # search every page
```

Fifteen local pages covering getting started, keybindings, tiling, the launcher and menu, terminal, Neovim, web apps, dictation, screenshots, updates and migrations, snapshots, Windows apps, troubleshooting, and gaming. Works in a TTY, over SSH, and with no network.

### Keybindings Browser

```bash
cosmarchy keybindings          # interactive filter (or Super + Alt + / / `c key ` in launcher)
cosmarchy keybindings --list   # plain text, for piping or grepping
cosmarchy keybindings reset    # re-deploy Cosmarchy's default COSMIC shortcuts
```

Reads directly from `/usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults` and `~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom`, so it always reflects active COSMIC bindings. To customize shortcuts, use **COSMIC Settings → Input Devices → Keyboard → Shortcuts**.

### Asus Laptops (ROG and TUF)

```bash
cosmarchy asus status            # model, asusd, graphics mode, charge limit
cosmarchy asus gui               # ROG Control Center
cosmarchy asus charge 80         # stop charging at 80% to spare the battery
cosmarchy asus profile           # quiet / balanced / performance
cosmarchy asus keyboard med      # backlight
cosmarchy asus graphics          # switch integrated / hybrid GPU
```

### Gaming

```bash
cosmarchy gaming install   # Steam, Proton-GE, Wine, Lutris, launchers, overlays
cosmarchy gaming status
cosmarchy gaming proton    # manage Proton versions
```

### Web Applications

```bash
cosmarchy webapp add "Claude" "https://claude.ai"
cosmarchy webapp add "Linear" "https://linear.app"
cosmarchy webapp list
cosmarchy webapp remove "Claude"
```

### Desktop Reminders

```bash
cosmarchy reminder 25m "Pomodoro break"
cosmarchy reminder 1h30m "Review PR"
cosmarchy reminder 17:30 "Team Standup"
cosmarchy reminder list
cosmarchy reminder cancel <id>
```

### Voxtype AI Speech-to-Text

```bash
cosmarchy voxtype toggle   # also bound to Super + D
cosmarchy voxtype status
```

### Windows Apps (WinBoat)

```bash
cosmarchy windows install
cosmarchy windows status
cosmarchy windows
```

### Rollback Snapshots & Boot Menu

```bash
cosmarchy snapshot create "Before system refactor"
cosmarchy snapshot list
cosmarchy snapshot restore 12
cosmarchy boot update      # regenerate Limine after editing /etc/kernel/cmdline
```

The Limine menu uses a fixed COSMIC Dark palette (`/etc/cosmarchy/boot-theme.conf`) and regenerates automatically on kernel updates, snapshots, and `mkinitcpio -P`. While booted into a snapshot, pacman and `cosmarchy update` refuse transactions so the ESP never drifts from root modules.

### Menu, Power & Screen Capture

```bash
cosmarchy menu               # flat gum filter over launcher/actions.tsv (TTY/SSH)
cosmarchy power <lock|suspend|logout|reboot|poweroff>
cosmarchy settings           # open COSMIC Settings
cosmarchy capture annotate   # region -> Satty annotation editor (Ctrl + Print)
cosmarchy capture region     # region -> ~/Pictures/Screenshots + clipboard
cosmarchy capture screen     # full screen
```

### System Updates, Migrations & Lifecycle Hooks

```bash
cosmarchy update             # Arch, AUR, Cosmarchy git pull, boot tooling, migrations
cosmarchy migrate --list     # inspect applied/pending migrations
cosmarchy migrate            # run pending migrations
cosmarchy hook list          # inspect lifecycle hooks (~/.config/cosmarchy/hooks/)
```

---

## Building the ISO Locally

```bash
# Install archiso on an Arch host
sudo pacman -S archiso git

# Run the ISO builder
sudo ./iso/builder/build-iso.sh
```

Test the resulting ISO in `./out/` with QEMU:

```bash
./run-vm.sh
```

---

## License

Cosmarchy is open-source software licensed under the **[MIT License](LICENSE)**.
