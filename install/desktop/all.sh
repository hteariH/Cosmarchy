#!/bin/bash

# Desktop configuration writes to dconf, which needs a live D-Bus session bus.
# Inside arch-chroot there is none, so every gsettings write would be silently
# discarded -- and custom keybindings, which cannot be expressed as gschema
# overrides, would be lost entirely. Defer the whole stage to first login.
cosmarchy_can_write_dconf() {
  [[ -z "$COSMARCHY_CHROOT_INSTALL" ]] || return 1
  [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" || -S "/run/user/$(id -u)/bus" ]] || return 1
  command -v gsettings >/dev/null 2>&1 || return 1
  return 0
}

# Extensions and their schemas are installed system-wide, so this part works
# without a session bus and must happen during installation.
source "$COSMARCHY_INSTALL/desktop/install-extension-files.sh"

if cosmarchy_can_write_dconf; then
  source "$COSMARCHY_INSTALL/desktop/set-gnome-settings.sh"
  source "$COSMARCHY_INSTALL/desktop/set-gnome-extensions.sh"
  source "$COSMARCHY_INSTALL/desktop/set-gnome-terminal.sh"
  source "$COSMARCHY_INSTALL/desktop/set-gnome-favorites.sh"
  source "$COSMARCHY_INSTALL/desktop/set-gnome-hotkeys.sh"
else
  cosmarchy_header "Deferring Desktop Configuration to First Login"
  cosmarchy_substep "No D-Bus session bus available in this context."
  cosmarchy_substep "Keyboard shortcuts and dconf settings will be applied at first login."

  mkdir -p "$HOME/.config/autostart"
  # Note: no X-GNOME-Autostart-Phase here. GNOME 50 and later run XDG autostart through
  # systemd-xdg-autostart-generator, which skips any entry that sets a startup
  # phase, because phases cannot be expressed as units. Setting it stopped this
  # entry from ever running.
  cat > "$HOME/.config/autostart/cosmarchy-first-run.desktop" <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Cosmarchy First Run Setup
Comment=Applies Cosmarchy desktop settings and keyboard shortcuts
Exec=/usr/local/bin/cosmarchy first-run
Icon=preferences-desktop
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
AUTOSTART

  cosmarchy_step "First-login setup scheduled"
fi

source "$COSMARCHY_INSTALL/desktop/set-nautilus-actions.sh"
