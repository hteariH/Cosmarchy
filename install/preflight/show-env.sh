#!/bin/bash

cosmarchy_header "System Pre-Flight Check"
cosmarchy_substep "Target User: $USER"
cosmarchy_substep "Install Destination: $COSMARCHY_PATH"
cosmarchy_substep "Kernel: $(uname -r)"
cosmarchy_substep "Chroot Mode: ${COSMARCHY_CHROOT_INSTALL:-false}"
