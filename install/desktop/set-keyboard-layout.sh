#!/bin/bash
# COSMIC keyboard layout from the layout picked in the installer.
# Writes com.system76.CosmicComp/v1/xkb_config as a plain RON file, so it runs
# directly inside the chroot rather than needing a live session.
# shellcheck source-path=SCRIPTDIR

if ! declare -F cosmarchy_cosmic_write >/dev/null 2>&1; then
  # shellcheck source=../helpers/cosmic.sh
  source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../helpers/cosmic.sh"
fi

KEYBOARD_CONF="${KEYBOARD_CONF:-/etc/cosmarchy/keyboard.conf}"
if [[ -f "$KEYBOARD_CONF" ]]; then
  xkb_layout="$(sed -n 's/^XKB_LAYOUT=//p' "$KEYBOARD_CONF")"
  xkb_variant="$(sed -n 's/^XKB_VARIANT=//p' "$KEYBOARD_CONF")"
  latin="$(sed -n 's/^LATIN=//p' "$KEYBOARD_CONF")"
  xkb_layout="${xkb_layout:-us}"

  # A non-Latin layout keeps US first so shortcuts and Latin input stay usable.
  # COSMIC stores active layouts as comma-aligned XKB layout and variant strings
  # (verified against cosmic-settings update_xkb_config at epoch-1.11.0).
  if [[ "$latin" == no ]]; then
    final_layout="us,${xkb_layout}"
    final_variant=",${xkb_variant}"
  else
    final_layout="$xkb_layout"
    final_variant="$xkb_variant"
  fi

  xkb_ron="$(printf '(\n    rules: "",\n    model: "",\n    layout: "%s",\n    variant: "%s",\n    options: None,\n    repeat_delay: 600,\n    repeat_rate: 25,\n)' \
    "$final_layout" "$final_variant")"
  cosmarchy_cosmic_write "com.system76.CosmicComp" "xkb_config" "$xkb_ron"

  if declare -F cosmarchy_step >/dev/null 2>&1; then
    cosmarchy_step "Keyboard layout: ${final_layout}${final_variant:+ ($final_variant)}"
  fi
fi
