#!/bin/bash

cosmarchy_header "Configuring the Limine Boot Menu"

# The ISO installer already deployed the boot tooling and fixed Limine palette
# before installing the bootloader; this run refreshes them and regenerates the menu.
if [[ -f /etc/cosmarchy/boot.conf ]]; then
  sudo bash "$COSMARCHY_PATH/default/boot/deploy.sh"
  sudo /usr/local/lib/cosmarchy/boot/cosmarchy-boot update
  cosmarchy_step "Limine menu generated"
else
  cosmarchy_warn "Not installed from the Cosmarchy ISO; the bootloader is left as it is."
fi
