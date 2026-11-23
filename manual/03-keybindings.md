# Keybindings

## Seeing what is bound

Press `Super + Alt + /` (or type `c key ` in COSMIC Launcher) to search your
active shortcuts directly inside COSMIC Launcher (read-only; activating closes
the launcher).

From any terminal, TTY, or SSH session:

```bash
cosmarchy keybindings          # interactive gum filter
cosmarchy keybindings --list   # plain text, for piping or grepping
cosmarchy keybindings reset    # restore Cosmarchy's default COSMIC shortcuts
```

`cosmarchy keybindings` reads directly from COSMIC's RON shortcut files:

    /usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults
    ~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom

So it always reflects the bindings actually in effect.

## Customizing shortcuts

COSMIC defaults win — Cosmarchy only binds keys that COSMIC leaves free.
To add or change shortcuts, open **COSMIC Settings → Input Devices → Keyboard
→ Shortcuts**, or edit `~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom`.

## Cosmarchy shortcuts

    Super + Return           COSMIC Terminal (cosmic-term)
    Super + E                COSMIC Files (cosmic-files)
    Super + D                Voxtype AI dictation toggle
    Ctrl + Print             Region screenshot into Satty annotator
    Super + Alt + Space      Cosmarchy actions in COSMIC Launcher (`c `)
    Super + Alt + /          Cosmarchy keybindings in COSMIC Launcher (`c key `)
    Super + Alt + M          Cosmarchy manual in COSMIC Launcher (`c man `)

`system_actions` also maps COSMIC's built-in `WebBrowser` (`Super + B`) to
Brave Origin (with Chromium / `xdg-open` fallback) and `Terminal` (`Super + T`)
to `cosmic-term`.

## Key COSMIC defaults

    Super                    COSMIC Launcher
    Super + A                COSMIC App Library
    Super + W                Workspace overview
    Super + B                Web browser (Brave Origin)
    Super + T                Terminal (COSMIC Terminal)
    Super + F                Home folder
    Super + Q                Close focused window
    Super + M                Maximize window
    Super + F11              Fullscreen window
    Super + Y                Toggle auto-tiling on this workspace
    Super + G                Float / tile focused window
    Super + O                Toggle tiling orientation
    Super + S                Toggle window stacking
    Super + H / J / K / L    Focus window (or arrow keys)
    Super + Shift + H/J/K/L  Move window (or arrow keys)
    Super + R                Resize window outwards (Super + Shift + R inwards)
    Super + 1..9             Switch to workspace 1..9
    Super + Shift + 1..9     Move window to workspace 1..9
    Super + Space            Switch keyboard input source
    Super + Escape           Lock screen
    Print                    COSMIC Screenshot
