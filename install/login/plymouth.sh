#!/bin/bash

cosmarchy_header "Configuring Plymouth Boot Splash"

# Install Cosmarchy Plymouth theme if present in default/plymouth
if [ -d "$COSMARCHY_PATH/default/plymouth" ]; then
  sudo mkdir -p /usr/share/plymouth/themes/cosmarchy
  sudo cp -r "$COSMARCHY_PATH/default/plymouth/"* /usr/share/plymouth/themes/cosmarchy/ 2>/dev/null || true
  
  if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    # -R rebuilds the initramfs, which is where the theme is read from at boot;
    # mkinitcpio's post hook then regenerates the Limine menu's hashes.
    if sudo plymouth-set-default-theme -R cosmarchy; then
      cosmarchy_substep "Plymouth theme: cosmarchy"
    elif sudo plymouth-set-default-theme -R bgrt; then
      cosmarchy_warn "The cosmarchy Plymouth theme did not apply; using bgrt"
    else
      cosmarchy_warn "Could not set a Plymouth theme; the boot splash keeps its default"
    fi
  fi
fi

# The plymouth hook is in /etc/mkinitcpio.conf.d/cosmarchy.conf, written by
# default/boot/deploy.sh. Editing HOOKS here used to insert it after `udev`,
# which a systemd HOOKS line never contains, so it never happened.

cosmarchy_step "Boot splash prepared"
