#!/bin/bash

cosmarchy_header "Setting Up Developer Tooling"

# Ensure pipx path is configured
pipx ensurepath >/dev/null 2>&1 || true

# mise comes from the official repositories (cosmarchy-base.packages).

# Claude Code, with Anthropic's native installer: it is not in the official
# repositories, and the installer keeps it updated itself, into ~/.local/bin.
if ! command -v claude >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/claude" ]]; then
  echo "Installing Claude Code..."
  if curl -fsSL https://claude.ai/install.sh | bash; then
    cosmarchy_substep "Claude Code installed"
  else
    # Not fatal: cosmarchy agent claude falls back to npx.
    cosmarchy_warn "Claude Code could not be installed; run: curl -fsSL https://claude.ai/install.sh | bash"
  fi
fi

# Install Paru AUR helper (pre-compiled x86_64 binary)
if ! command -v paru >/dev/null 2>&1; then
  echo "Installing Paru AUR helper..."
  mkdir -p /tmp/paru-install
  if curl -sL "https://github.com/Morganamilo/paru/releases/download/v2.1.0/paru-v2.1.0-x86_64.tar.zst" -o /tmp/paru-install/paru.tar.zst 2>/dev/null; then
    tar -xf /tmp/paru-install/paru.tar.zst -C /tmp/paru-install/ 2>/dev/null || true
    if [ -f /tmp/paru-install/paru ]; then
      sudo cp -f /tmp/paru-install/paru /usr/local/bin/paru 2>/dev/null || true
      sudo chmod +x /usr/local/bin/paru 2>/dev/null || true
    fi
  fi
  rm -rf /tmp/paru-install
fi

cosmarchy_step "Developer tooling configured"
