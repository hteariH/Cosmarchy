#!/bin/bash

# COSMIC stores its configuration as plain RON files under ~/.config/cosmic/,
# so the desktop stage deploys directly inside arch-chroot without needing a
# D-Bus session bus or a desktop-config first-run autostart pass.
source "$COSMARCHY_INSTALL/desktop/cosmic.sh"
source "$COSMARCHY_INSTALL/desktop/set-keyboard-layout.sh"
