#!/bin/bash

# Install the Cosmarchy pop-launcher plugin symlink.
# Works offline inside arch-chroot (plain symlink under $HOME/.local/share).
COSMARCHY_PATH="${COSMARCHY_PATH:-$HOME/.local/share/cosmarchy}"

declare -F cosmarchy_header >/dev/null 2>&1 || cosmarchy_header() { echo "==> $*"; }
declare -F cosmarchy_step >/dev/null 2>&1 || cosmarchy_step() { echo "  -> $*"; }
declare -F cosmarchy_error >/dev/null 2>&1 || cosmarchy_error() { echo "ERROR: $*" >&2; }

cosmarchy_header "Installing Cosmarchy Launcher Plugin"

PLUGIN_SRC="$COSMARCHY_PATH/launcher/cosmarchy"
PLUGINS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pop-launcher/plugins"
PLUGIN_LINK="$PLUGINS_DIR/cosmarchy"

if [[ ! -d "$PLUGIN_SRC" ]]; then
  cosmarchy_error "Launcher plugin source not found at $PLUGIN_SRC"
  return 1 2>/dev/null || exit 1
fi

chmod +x "$PLUGIN_SRC/cosmarchy-launcher"
mkdir -p "$PLUGINS_DIR"
ln -sfn "$PLUGIN_SRC" "$PLUGIN_LINK"

cosmarchy_step "Linked Cosmarchy pop-launcher plugin at $PLUGIN_LINK"
