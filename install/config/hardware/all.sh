#!/bin/bash

cosmarchy_header "Detecting & Applying Hardware Profiles"

source "$COSMARCHY_INSTALL/config/hardware/apple/fix-t2.sh"
source "$COSMARCHY_INSTALL/config/hardware/asus.sh"
source "$COSMARCHY_INSTALL/config/hardware/framework.sh"
source "$COSMARCHY_INSTALL/config/hardware/intel/video-acceleration.sh"
source "$COSMARCHY_INSTALL/config/hardware/nvidia.sh"

cosmarchy_step "Hardware profiling complete"
