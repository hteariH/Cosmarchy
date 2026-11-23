# Neovim

Neovim is set up with the stock **LazyVim** starter. First launch syncs plugins
and takes a moment.

## Your own configuration

Everything under `~/.config/nvim/` is yours — Cosmarchy does not overwrite your
colorscheme or plugins. Add specs under `~/.config/nvim/lua/plugins/` as you
would with any LazyVim setup.

If you already had a Neovim configuration when Cosmarchy was installed, it was
left untouched and no LazyVim bootstrap was written.

## The editor for quick edits

VS Code (`code`) is the graphical default and what opens for text files from
COSMIC Files. In a TTY or over SSH you get `nano`, which needs no prior
knowledge.

`$EDITOR` follows the same split: `code --wait` under a graphical session,
`nano` without one. The `--wait` is not optional — without it git sees the
editor exit immediately and treats your commit message as empty.

Neovim is installed and ready whenever you want it. Run `nvim`, or set
`EDITOR=nvim` in your own shell configuration.
