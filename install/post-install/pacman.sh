#!/bin/bash

cosmarchy_header "Cleaning Package Cache"
sudo pacman -Sc --noconfirm >/dev/null 2>&1 || true
cosmarchy_step "Package caches cleaned"
