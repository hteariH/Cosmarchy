#!/bin/bash

cosmarchy_header "Configuring the Limine Boot Menu"

# The ISO installer already deployed the boot tooling before installing the
# bootloader; this run finds it in place and only regenerates the menu with
# the theme set in the config stage.
if [[ -f /etc/cosmarchy/boot.conf ]]; then
  sudo bash "$COSMARCHY_PATH/default/boot/deploy.sh"
  sudo /usr/local/lib/cosmarchy/boot/cosmarchy-boot update
  cosmarchy_step "Limine menu generated"
else
  cosmarchy_warn "Not installed from the Cosmarchy ISO; the bootloader is left as it is."
fi
