#!/bin/bash
# Tests COSMIC config deployment and installer keyboard layout -> xkb_config.
set -u
cd "$(dirname "$0")/../.." || exit 1
# shellcheck source=iso/tests/lib/assert.sh
source iso/tests/lib/assert.sh
# shellcheck source=install/helpers/cosmic.sh
source install/helpers/cosmic.sh

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

echo "--- cosmarchy_cosmic_deploy"
t_true "deploy default/cosmic/ tree" cosmarchy_cosmic_deploy "$PWD/default/cosmic" "$T/cosmic"
for rel in \
  com.system76.CosmicComp/v1/autotile \
  com.system76.CosmicComp/v1/autotile_behavior \
  com.system76.CosmicSettings.Shortcuts/v1/custom \
  com.system76.CosmicSettings.Shortcuts/v1/system_actions; do
  t_true "deployed $rel matches source" cmp -s "default/cosmic/$rel" "$T/cosmic/$rel"
done

echo "--- custom shortcuts sanity"
CUSTOM="default/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
t_eq "seven custom bindings shipped" "$(grep -c 'modifiers:' "$CUSTOM")" "7"
t_true "keybindings on Super+Alt+slash" grep -q 'modifiers: \[Super, Alt\], key: "slash".*cosmic-term -e cosmarchy-keybindings' "$CUSTOM"
t_true "manual on Super+Alt+m" grep -q 'modifiers: \[Super, Alt\], key: "m".*cosmic-term -e cosmarchy-manual' "$CUSTOM"
t_true "menu on Super+Alt+space" grep -q 'modifiers: \[Super, Alt\], key: "space".*cosmic-term -e cosmarchy-menu' "$CUSTOM"
t_false "no screensaver shortcut" grep -qi 'screensaver' "$CUSTOM"

echo "--- set-keyboard-layout.sh -> xkb_config"
printf 'XKB_LAYOUT=de\nXKB_VARIANT=\nLATIN=yes\n' >"$T/kb-de.conf"
t_true "latin layout (de)" env XDG_CONFIG_HOME="$T/h-de" KEYBOARD_CONF="$T/kb-de.conf" bash install/desktop/set-keyboard-layout.sh
t_true "de writes layout: \"de\"" grep -qF 'layout: "de",' "$T/h-de/cosmic/com.system76.CosmicComp/v1/xkb_config"
t_true "de writes variant: \"\"" grep -qF 'variant: "",' "$T/h-de/cosmic/com.system76.CosmicComp/v1/xkb_config"

printf 'XKB_LAYOUT=us\nXKB_VARIANT=intl\nLATIN=yes\n' >"$T/kb-intl.conf"
t_true "latin layout with variant (us-intl)" env XDG_CONFIG_HOME="$T/h-intl" KEYBOARD_CONF="$T/kb-intl.conf" bash install/desktop/set-keyboard-layout.sh
t_true "us-intl writes layout: \"us\"" grep -qF 'layout: "us",' "$T/h-intl/cosmic/com.system76.CosmicComp/v1/xkb_config"
t_true "us-intl writes variant: \"intl\"" grep -qF 'variant: "intl",' "$T/h-intl/cosmic/com.system76.CosmicComp/v1/xkb_config"

printf 'XKB_LAYOUT=ru\nXKB_VARIANT=\nLATIN=no\n' >"$T/kb-ru.conf"
t_true "non-latin layout (ru)" env XDG_CONFIG_HOME="$T/h-ru" KEYBOARD_CONF="$T/kb-ru.conf" bash install/desktop/set-keyboard-layout.sh
t_true "ru keeps US first (us,ru)" grep -qF 'layout: "us,ru",' "$T/h-ru/cosmic/com.system76.CosmicComp/v1/xkb_config"
t_true "ru aligns variant comma" grep -qF 'variant: ",",' "$T/h-ru/cosmic/com.system76.CosmicComp/v1/xkb_config"

t_done
