#!/bin/bash

# Ensure ~/.bashrc sources Cosmarchy configurations
BASHRC_SRC='[ -f "$HOME/.local/share/cosmarchy/default/bash/bashrc" ] && source "$HOME/.local/share/cosmarchy/default/bash/bashrc"'

if [ -f "$HOME/.bashrc" ]; then
  if ! grep -q "cosmarchy/default/bash/bashrc" "$HOME/.bashrc"; then
    echo -e "\n# Cosmarchy configuration\n$BASHRC_SRC" >> "$HOME/.bashrc"
  fi
else
  echo -e "# Cosmarchy configuration\n$BASHRC_SRC" > "$HOME/.bashrc"
fi

# Ensure executable permissions and global PATH availability
chmod +x "$HOME/.local/share/cosmarchy/bin"/* 2>/dev/null || true
sudo ln -sf "$HOME/.local/share/cosmarchy/bin/cosmarchy" /usr/local/bin/cosmarchy 2>/dev/null || true
sudo chmod +x /usr/local/bin/cosmarchy 2>/dev/null || true

# System-wide profile hook
if [ -d /etc/profile.d ]; then
  sudo tee /etc/profile.d/cosmarchy.sh >/dev/null <<'PROFILE_EOF'
if [ -d "$HOME/.local/share/cosmarchy/bin" ]; then
  case ":$PATH:" in
    *:"$HOME/.local/share/cosmarchy/bin":*) ;;
    *) export PATH="$HOME/.local/share/cosmarchy/bin:$PATH" ;;
  esac
fi
PROFILE_EOF
fi
