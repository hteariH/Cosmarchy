# Terminal

**COSMIC Terminal** (`cosmic-terminal`, binary `cosmic-term`) is the default
terminal. Press `Super + Return` or `Super + T` to open one.

COSMIC Terminal follows COSMIC's native appearance and settings directly —
customize font, color scheme, opacity, and profiles from its own Settings menu.

## Shell

Bash with `starship`, `zoxide`, and `mise`. Aliases live in:

    ~/.local/share/cosmarchy/default/bash/aliases

Note that `grep`, `find`, and `cat` are deliberately not shadowed by `rg`, `fd`,
and `bat`. Scripts and muscle memory depend on their real flags; the modern
tools are available under their own names (`rgi`, `catp`, `fd`, `rg`, `bat`,
`eza`).
