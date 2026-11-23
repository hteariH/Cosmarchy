# The Launcher & Menu

Cosmarchy integrates directly into **COSMIC Launcher** (`pop-launcher`) under
the `c ` prefix, so actions, keybindings, and manual pages appear natively in
the stock launcher without a separate control-center window.

## Shortcuts and prefixes

    Super + Alt + Space     COSMIC Launcher prefilled with `c ` (actions)
    Super + Alt + /         COSMIC Launcher prefilled with `c key ` (keybindings)
    Super + Alt + M         COSMIC Launcher prefilled with `c man ` (manual pages)

You can also press `Super` for COSMIC Launcher and type `c `, `c key `, or
`c man ` directly.

- **Actions (`c <query>`)** — single catalog in `launcher/actions.tsv` covering
  tiling, screen capture, snapshots, system updates, COSMIC Settings, web apps,
  gaming, keybindings, manual, and power:
  - *Immediate* (`run`) actions execute and close the launcher (e.g. toggle
    auto-tiling, screen capture, lock, suspend, COSMIC Settings).
  - *Status* (`notify`) actions run and show their output via `notify-send`
    (e.g. tiling status, gaming status, web app list, system info).
  - *Interactive* (`terminal`) actions open `cosmic-term -e <cmd>` for input or
    confirmation (e.g. create/list/restore snapshots, update everything, web app
    add/remove, logout/reboot/power off).
- **Keybindings (`c key <query>`)** — read-only search over active COSMIC and
  Cosmarchy shortcuts from `cosmarchy-keybindings --list`; activating closes
  the launcher.
- **Manual (`c man <query>`)** — search local manual pages from
  `cosmarchy-manual --list`; activating opens `cosmic-term -e cosmarchy-manual <page>`.

## Terminal / SSH fallback (`cosmarchy menu`)

In a console TTY or over SSH, `cosmarchy menu` opens a flat `gum filter` picker
over the same `launcher/actions.tsv` catalog. Everything in the catalog is also
a plain CLI command:

```bash
cosmarchy menu
cosmarchy keybindings
cosmarchy manual
cosmarchy tiling toggle
cosmarchy capture annotate
cosmarchy snapshot list
cosmarchy power reboot
```
