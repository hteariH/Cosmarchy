#!/bin/bash

cosmarchy_header "Initializing Default Cosmarchy Theme"

mkdir -p "$HOME/.config/cosmarchy/themes"
mkdir -p "$HOME/.config/cosmarchy/backgrounds"

# 1. Install the bundled SVG wallpapers, one directory per theme. These are
#    generated in-repo and act as the offline fallback when the upstream
#    download below is unavailable.
echo "Installing bundled fallback wallpapers..."
sudo mkdir -p /usr/share/backgrounds/cosmarchy 2>/dev/null || true
for theme_dir in "$COSMARCHY_PATH"/themes/*/; do
  theme_name="$(basename "$theme_dir")"
  for bg in "$theme_dir"backgrounds/*; do
    [ -f "$bg" ] || continue
    sudo mkdir -p "/usr/share/backgrounds/cosmarchy/$theme_name" 2>/dev/null || true
    sudo cp -f "$bg" "/usr/share/backgrounds/cosmarchy/$theme_name/" 2>/dev/null || true
  done
done
sudo chmod -R 755 /usr/share/backgrounds/cosmarchy 2>/dev/null || true
sudo find /usr/share/backgrounds/cosmarchy -type f -exec chmod 644 {} + 2>/dev/null || true

# 2. Fetch the upstream Omarchy wallpapers onto this machine. Cosmarchy does
#    not redistribute them; see BACKGROUNDS.md. A failure here is not fatal --
#    the SVG fallbacks installed above keep every theme usable offline.
if command -v cosmarchy-backgrounds >/dev/null 2>&1; then
  cosmarchy-backgrounds || echo "  Background download skipped; using bundled fallbacks."
elif [ -x "$COSMARCHY_PATH/bin/cosmarchy-backgrounds" ]; then
  "$COSMARCHY_PATH/bin/cosmarchy-backgrounds" || echo "  Background download skipped; using bundled fallbacks."
fi

# 3. Initialize default theme (Tokyo Night)
if command -v cosmarchy-theme-set >/dev/null 2>&1; then
  cosmarchy-theme-set "tokyo-night" || true
elif [ -f "$COSMARCHY_PATH/bin/cosmarchy-theme-set" ]; then
  "$COSMARCHY_PATH/bin/cosmarchy-theme-set" "tokyo-night" || true
fi

cosmarchy_step "Tokyo Night theme initialized"
