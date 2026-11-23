#!/bin/bash

cosmarchy_header "Deploying COSMIC Desktop Configuration"

# Plain RON files in ~/.config/cosmic/ work directly inside arch-chroot with
# no D-Bus session bus, so behaviour-only COSMIC settings (tiling defaults and
# non-conflicting shortcuts) are deployed here rather than deferred.
cosmarchy_cosmic_deploy "$COSMARCHY_PATH/default/cosmic" "$HOME/.config/cosmic"

cosmarchy_step "COSMIC configuration deployed to $HOME/.config/cosmic"
