#!/bin/bash
# The fixed COSMIC Dark Limine palette must be complete and valid.
set -u
cd "$(dirname "$0")/../.." || exit 1
# shellcheck source=iso/tests/lib/assert.sh
source iso/tests/lib/assert.sh
# shellcheck source=default/boot/lib/palette.sh
source default/boot/lib/palette.sh

PALETTE="default/boot/boot-theme.conf"
out="$(boot_palette_validate "$PALETTE")"
t_eq "cosmic dark background" "$(sed -n 's/^BACKGROUND=//p' <<<"$out")" "1b1b1b"
t_eq "cosmic dark foreground" "$(sed -n 's/^FOREGROUND=//p' <<<"$out")" "c4c4c4"
t_eq "cosmic dark accent" "$(sed -n 's/^ACCENT=//p' <<<"$out")" "49bac8"
t_eq "normal black is NORMAL_0" "$(sed -n 's/^NORMAL_0=//p' <<<"$out")" "1b1b1b"
t_eq "bright white is BRIGHT_7" "$(sed -n 's/^BRIGHT_7=//p' <<<"$out")" "c4c4c4"
t_eq "palette yields 19 hex values" "$(grep -cE '^[A-Z0-9_]+=[0-9a-f]{6}$' <<<"$out")" "19"

# Verify boot_theme_lines consumes the static file cleanly.
T="$(mktemp -d)"
mkdir -p "$T/etc/cosmarchy"
cp "$PALETTE" "$T/etc/cosmarchy/boot-theme.conf"
export COSMARCHY_BOOT_ROOT="$T"
# shellcheck source=default/boot/lib/common.sh
source default/boot/lib/common.sh
# shellcheck source=default/boot/lib/menu.sh
source default/boot/lib/menu.sh
rendered="$(boot_theme_lines)"
t_true "rendered interface_branding_colour" grep -qxF "interface_branding_colour: 49bac8" <<<"$rendered"
t_true "rendered term_background" grep -qxF "term_background: 001b1b1b" <<<"$rendered"
t_true "rendered term_foreground" grep -qxF "term_foreground: c4c4c4" <<<"$rendered"
t_true "rendered term_palette" grep -qxF "term_palette: 1b1b1b;f16161;7cb987;ddc74c;6296be;be6dee;49bac8;bebebe" <<<"$rendered"
t_true "rendered term_palette_bright" grep -qxF "term_palette_bright: 808080;ff8985;97d5a0;fae365;7db1da;d68eff;49bac8;c4c4c4" <<<"$rendered"
unset COSMARCHY_BOOT_ROOT

tmp="$(mktemp)"
printf 'BACKGROUND=1b1b1b\n' >"$tmp"
err="$(boot_palette_validate "$tmp" 2>&1)" && t_no "a palette with missing colours is rejected" || t_ok "a palette with missing colours is rejected"
t_true "the error names the missing colour" grep -q "has no FOREGROUND" <<<"$err"

sed 's/^ACCENT=.*/ACCENT=nothex/' "$PALETTE" >"$tmp"
err="$(boot_palette_validate "$tmp" 2>&1)" && t_no "a palette with malformed hex is rejected" || t_ok "a palette with malformed hex is rejected"
t_true "the error names the invalid colour" grep -q "invalid ACCENT" <<<"$err"

rm -rf "$T" "$tmp"
t_done
