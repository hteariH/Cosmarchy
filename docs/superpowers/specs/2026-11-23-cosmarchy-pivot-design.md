# Cosmarchy pivot — design

Date: 2026-11-23. Status: approved.

Gnomarchy becomes **Cosmarchy**: the same Omarchy-derived Arch base, installer,
CLI and tooling, with the **COSMIC** desktop (1.11, Arch `extra`) instead of
GNOME. This spec is phase 1 of 2. Phase 2 — a control center written in
libcosmic (Rust) — gets its own spec later; until then the menu, keybindings
and manual are text-only.

## Decisions

| Topic | Decision |
|---|---|
| Repository | Pivot in place. Rename everything `gnomarchy` → `cosmarchy`. |
| Existing installs | None exist. No GNOME→COSMIC migration. `migrations/*` is emptied; the migration mechanism and baseline stay. |
| Look | Authentic stock COSMIC. No theme engine, no Omarchy themes, no downloaded wallpapers. |
| Apps | Native COSMIC apps. Default terminal is `cosmic-terminal`. Alacritty, gnome-terminal, Nautilus are dropped. |
| First login | `cosmic-initial-setup` is kept: it handles language, keyboard, timezone, Wi-Fi, accessibility, appearance and panel layout. Cosmarchy does not override what it asks. |
| Config delivery | Plain RON files written by the installer inside the chroot (approach A). No dconf, no first-run autostart for desktop settings. |
| Shortcuts | COSMIC defaults win. Cosmarchy shortcuts use only keys COSMIC leaves free. |
| GUI | `gui/` (GJS/libadwaita) is deleted. Phase 2 replaces it. |
| Version | First Cosmarchy release is `v0.1.0`. |

## Verified facts (COSMIC 1.11.0, Arch `extra`, checked 2026-11-23)

Package names — note the traps: the terminal is **`cosmic-terminal`** and the
editor **`cosmic-text-editor`**, not `cosmic-term` / `cosmic-edit`.

```
cosmic-session cosmic-comp cosmic-greeter cosmic-settings cosmic-settings-daemon
cosmic-panel cosmic-launcher cosmic-app-library cosmic-applets cosmic-notifications
cosmic-osd cosmic-bg cosmic-idle cosmic-workspaces cosmic-randr cosmic-screenshot
xdg-desktop-portal-cosmic cosmic-icon-theme cosmic-wallpapers cosmic-initial-setup
cosmic-files cosmic-terminal cosmic-text-editor cosmic-player cosmic-store
```

Verify every name again with the archlinux.org JSON API before committing the
package list (CLAUDE.md, *Verifying package names*).

**Greeter.** `cosmic-greeter` runs under `greetd` (0.10.x). It ships
`cosmic-greeter.service` (patched by Arch to be the display manager),
`cosmic-greeter-daemon.service`, and `/etc/greetd/cosmic-greeter.toml`
(a pacman `backup` file):

```toml
[terminal]
vt = "1"
[general]
service = "cosmic-greeter"
[default_session]
command = "cosmic-greeter-start"
user = "cosmic-greeter"
```

Autologin = add an `[initial_session]` table with `command = "start-cosmic"`
and `user = "<username>"`. The session binary is `/usr/bin/start-cosmic`
(`cosmic-session` package, `/usr/share/wayland-sessions/cosmic.desktop`).
Confirm which PAM service greetd uses for the user session by reading the
installed `/etc/pam.d/` files in the built image; add `pam_gnome_keyring`
there the way `gdm.sh` did.

**Config storage.** `cosmic-config` reads per-key files:
`~/.config/cosmic/<component-id>/v1/<key>`, falling back to
`/usr/share/cosmic/<component-id>/v1/<key>` (owned by packages — never write
there).

**Shortcuts.** Component `com.system76.CosmicSettings.Shortcuts`:
- `defaults` ships in `/usr/share/cosmic/.../v1/defaults` (from `cosmic-comp`).
- user key `custom` is merged with `defaults.extend(custom)` — a custom
  binding on the same key **replaces** the default.
- user key `system_actions` overrides what `System(...)` actions run
  (e.g. `WebBrowser`, `Terminal`, `HomeFolder`).
- A parse error is logged by `cosmic-settings-daemon` as
  `shortcuts custom config error` — the session test greps for it.

RON syntax (from `cosmic-comp` `data/keybindings.ron`):

```ron
{
    (modifiers: [Super], key: "Return"): Spawn("cosmic-term"),
    (modifiers: [Super, Alt], key: "k"): Spawn("cosmarchy-keybindings"),
}
```

Actions include `Close`, `Maximize`, `Fullscreen`, `Workspace(u8)`,
`MoveToWorkspace(u8)`, `ToggleTiling`, `Spawn(String)`, `System(...)`,
`Disable`. Check the exact `system_actions` RON shape against
`cosmic-settings-daemon` `config/src/shortcuts/` at tag `epoch-1.11.0`
before writing it.

COSMIC defaults that matter here: `Super+Q` Close, `Super+W` workspace
overview, `Super+K`/`Super+Shift+K` focus/move up, `Super+Escape` lock,
`Super+B` WebBrowser, `Super+F` HomeFolder, `Super+T` Terminal,
`Super+1..9` workspaces, `Super+Shift+1..9` move to workspace, `Print`
screenshot, `Super` alone launcher.

**Initial setup.** `cosmic-initial-setup` autostarts in the session and exits
immediately when `~/.config/cosmic-initial-setup-done` exists. The unattended
(CI) install creates that file; a normal install does not.

**Tiling.** `com.system76.CosmicComp/v1/autotile` (`true`) and
`autotile_behavior` (`PerWorkspace`). Confirm key names against
`cosmic-comp` config at `epoch-1.11.0`.

## Architecture

### Packages — `install/cosmarchy-base.packages`

Remove: `gdm gnome-shell mutter gnome-control-center gnome-tweaks
gnome-browser-connector gnome-shell-extension-appindicator extension-manager
xdg-desktop-portal-gnome polkit-gnome nautilus nautilus-python sushi
gnome-terminal gnome-text-editor gnome-system-monitor alacritty gjs
libadwaita` and anything else only GNOME or the deleted GUI/theme engine
needed.

Add: the COSMIC list above, listed by name (not the `cosmic` group), so
`install/packaging/base.sh` keeps partitioning names against the sync DBs.

Keep: `xdg-desktop-portal-gtk gtk3 gtk4 gnome-keyring loupe evince
gnome-calculator` (GTK apps without a COSMIC equivalent; keyring is the
secret store, not the shell). Polkit agent comes from `cosmic-osd`.

### Login — `install/login/greeter.sh` (replaces `gdm.sh`)

Disable competing display managers (`gdm sddm lightdm`) — reporting, not
hiding, failures other than "unit does not exist". Enable
`cosmic-greeter.service`. On an encrypted disk, write `[initial_session]`
autologin into `/etc/greetd/cosmic-greeter.toml`. Add keyring PAM lines.
Plymouth, limine and snapper are unchanged.

### COSMIC config — `default/cosmic/` + `install/desktop/cosmic.sh`

`default/cosmic/` mirrors `~/.config/cosmic/` one file per key and holds
**behaviour only**:

```
com.system76.CosmicComp/v1/autotile
com.system76.CosmicComp/v1/autotile_behavior
com.system76.CosmicSettings.Shortcuts/v1/custom
com.system76.CosmicSettings.Shortcuts/v1/system_actions
```

`install/helpers/cosmic.sh` provides `cosmarchy_cosmic_deploy`, which copies
the tree into `$HOME/.config/cosmic` (atomic: temp file + `mv`; no error
suppression). `install/desktop/all.sh` calls it inside the chroot. The
`gnomarchy_can_write_dconf` check and the desktop-config autostart path are
removed.

Shortcuts in `custom` (COSMIC defaults win; free keys only):

| Key | Action |
|---|---|
| `Super+Return` | `Spawn("cosmic-term")` |
| `Super+E` | files (`cosmic-files`) |
| `Super+D` | `cosmarchy voxtype toggle` |
| `Ctrl+Print` | `cosmarchy-capture annotate` |
| `Super+Alt+Space` | `cosmarchy-menu` |
| `Super+Alt+K` | `cosmarchy-keybindings` |
| `Super+Alt+Shift+K` | `cosmarchy-manual` |
| `Super+Alt+Escape` | `cosmarchy screensaver` |

Before using any key, confirm it is absent from COSMIC's `defaults`.
`system_actions`: `WebBrowser` → the Brave fallback chain from the old
`set-gnome-hotkeys.sh`; `Terminal` → `cosmic-term`.

### first-run

`cosmarchy-first-run` keeps only work that needs a live session (whatever
`set-hardware-session.sh` does: PipeWire, seat, hardware). If nothing is left,
delete it and its autostart entry. Any autostart entry that remains must not
contain `X-GNOME-Autostart-Phase` (CLAUDE.md).

### Removed

`gui/`, `install/config/control-center.sh`, GUI-only helpers;
`install/desktop/*` GNOME scripts and Python extension installers;
`bin/*-gnome-{extensions,hotkeys,restart,scaling}`; `themes/`,
`bin/*-theme-{set,list,current}`, `install/config/theme.sh`;
`bin/*-backgrounds`, `install/backgrounds.manifest`, `BACKGROUNDS.md`;
`default/{gdm,gnome,nautilus,alacritty,themed}` and theme-generated configs;
`manual/05-themes.md`, `manual/06-backgrounds.md`; `migrations/*`.
nvim, btop and starship use their own defaults (no generated colourscheme,
no LazyVim colourscheme pin).

### Reworked commands

`cosmarchy-tiling` → toggles `autotile`. Every remaining `bin/` command is
audited for `gsettings`, `dconf`, `gnome-*`, `nautilus`, `gnome-terminal`,
`alacritty`, `mutter`: port it to COSMIC / wl-clipboard / cosmic-term, or
remove the feature together with its manual and README text.
`cosmarchy-keybindings` / `cosmarchy-manual` / `cosmarchy-menu` keep only
their text paths.

### Rename

Mechanical, in its own commit, no logic change: `GNOMARCHY_*`,
`gnomarchy_*`, `bin/cosmarchy*`, `~/.local/share/cosmarchy`,
`~/.local/state/cosmarchy`, unattended label `COSMARCHY` and file
`cosmarchy-unattended.conf`, ISO name, Plymouth theme, AI skill, `site/`,
README, `AGENTS.md`, `CLAUDE.md`, `manual/`, workflows. Use `git mv` so
history follows. New scripts need `git update-index --chmod=+x`.
The GitHub repository and the Cloudflare Pages project are renamed later, by
hand, after confirmation — not by this change.

## Verification

`iso/tests/verify-install.sh` (offline image):
- every file in `default/cosmic/` exists byte-identical in the user's
  `~/.config/cosmic/`;
- no `gnome-shell`, `gdm`, `mutter` installed; every COSMIC package installed;
- `cosmic-greeter.service` enabled; no GDM unit; keyring PAM line present;
- no `gnomarchy` string in `/usr/local/bin` symlink names or `$HOME` paths;
- existing non-GNOME checks keep working (snapper, limine, symlinks, exec bits).

`iso/tests/verify-session.sh` (live COSMIC autologin session):
- `cosmic-comp`, `cosmic-panel`, `cosmic-settings-daemon` running;
- no `shortcuts custom config error` / `system_actions` error in the journal;
- every Cosmarchy shortcut key is absent from COSMIC `defaults` (no silent
  override);
- `autotile` true; `xdg-desktop-portal-cosmic` answers on the bus.

CI autologin uses greetd `[initial_session]`; the unattended installer writes
`~/.config/cosmic-initial-setup-done`. The smoke-test workflow is updated for
the new names, label and session. GNOME-only checks are deleted, not skipped.

## Addendum — base moved to v0.0.8

The design above was first drafted against v0.0.6. `main` has since gained a
gum installer, Limine with bootable snapshots, WinBoat, GSConnect and more.
These rules apply on top of everything above:

- **Already gone upstream:** Alacritty and the retro screensaver were dropped in
  v0.0.7. No screensaver shortcut; the shortcut table loses `Super+Alt+Escape`.
- **Shortcut keys, corrected.** `Super+Alt+K`, `Super+Alt+Shift+K` and
  `Super+Alt+Escape` are COSMIC defaults (`SwitchOutput(Up)`,
  `MoveToOutput(Up)`, `Terminate`). Use `Super+Alt+slash` for keybindings and
  `Super+Alt+M` for the manual. Text tools spawn as `cosmic-term -e <cmd>`.
- **Limine palette.** `default/boot/lib/palette.sh` derives the boot menu
  palette from a theme's `alacritty.toml`. With no themes, ship one fixed
  palette matching COSMIC's default dark theme as a static file and write
  `/etc/cosmarchy/boot-theme.conf` from it at install time. Drop the
  theme-set → palette path; keep `iso/tests/test-palette.sh` meaningful.
- **Keyboard layout.** The installer's chosen XKB layout/variant (written to
  the keyboard conf by `iso/installer/lib/stages.sh`) must reach COSMIC:
  write it to `com.system76.CosmicComp/v1/xkb_config` (check the exact RON
  shape in `cosmic-comp` at `epoch-1.11.0`) instead of the gsettings path in
  `install/desktop/set-keyboard-layout.sh`. Keep the `us` + latin fallback
  logic it has.
- **GSConnect → KDE Connect.** Replace the bundled GSConnect extension with
  the `kdeconnect` package (extra). Keep the ufw rules for ports 1714-1764.
- **Snapshots, WinBoat, desktop apps.** Audit them like every other command:
  anything that touches the theme, dconf or GNOME is ported or removed.
- **Fast tests.** `iso/tests/unit.sh` (all `test-*.sh` + shellcheck) must
  stay green. Run it in `archlinux:latest` via Docker if available.

## Out of scope

The libcosmic control center (phase 2); GNOME support of any kind; migrating
existing machines; renaming the GitHub repo / Pages project.
