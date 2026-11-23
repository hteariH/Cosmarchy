#!/bin/bash

cosmarchy_header "Deploying Developer Tool Configurations"

DEFAULTS="$COSMARCHY_PATH/default"

# Neovim: LazyVim bootstrap. Existing user configs are left untouched.
if [[ -d "$DEFAULTS/nvim" ]]; then
  if [[ -f "$HOME/.config/nvim/init.lua" ]] && ! grep -q "config.lazy" "$HOME/.config/nvim/init.lua" 2>/dev/null; then
    echo "  Existing Neovim config detected - leaving it untouched."
  else
    mkdir -p "$HOME/.config/nvim/lua/plugins"
    cp -f "$DEFAULTS/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    mkdir -p "$HOME/.config/nvim/lua/config"
    cp -f "$DEFAULTS/nvim/lua/config/lazy.lua" "$HOME/.config/nvim/lua/config/lazy.lua"
    echo "  Installed LazyVim bootstrap (plugins sync on first nvim launch)"
  fi
fi

cosmarchy_step "Developer tool configurations deployed"
