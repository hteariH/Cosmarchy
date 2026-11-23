# Tiling

Cosmarchy enables **COSMIC's built-in compositor auto-tiling** per workspace
(`autotile = true`, `autotile_behavior = PerWorkspace`).

```bash
cosmarchy tiling status    # show current autotile state and behavior
cosmarchy tiling enable    # turn automatic tiling on
cosmarchy tiling disable   # turn automatic tiling off
cosmarchy tiling toggle    # flip automatic tiling on/off
```

Changes write atomically to
`~/.config/cosmic/com.system76.CosmicComp/v1/autotile`, and `cosmic-comp`
applies them immediately.

## Keys (COSMIC built-in)

    Super + Y                  toggle auto-tiling for the active workspace
    Super + G                  float or tile the focused window
    Super + O                  toggle tiling orientation (horizontal / vertical)
    Super + S                  toggle window stacking (tabbed group)
    Super + H / J / K / L      focus window left / down / up / right (or arrows)
    Super + Shift + H/J/K/L    move window left / down / up / right (or arrows)
    Super + X                  swap focused window
    Super + R                  resize window outwards
    Super + Shift + R          resize window inwards

## Per-workspace behavior

Because `autotile_behavior` is set to `PerWorkspace`, pressing `Super + Y`
toggles tiling only on the workspace you are currently viewing. Other
workspaces keep their own state, and floating individual dialogs or utility
windows works with `Super + G`.
