#!/bin/bash
# Static COSMIC Dark palette validation for the Limine boot menu.
#
# Cosmarchy ships one fixed palette at default/boot/boot-theme.conf, deployed
# to /etc/cosmarchy/boot-theme.conf by default/boot/deploy.sh and read by
# cosmarchy-boot.

# boot_palette_validate FILE — verifies FILE defines BACKGROUND, FOREGROUND,
# ACCENT, NORMAL_0..7 and BRIGHT_0..7 as 6-digit hex (rrggbb), printing the
# normalized lowercase KEY=rrggbb lines, or fails naming the first bad key.
boot_palette_validate() {
  local file="$1" line key val i
  local -A colour=()

  if [[ ! -f "$file" ]]; then
    printf 'palette: no such file: %s\n' "$file" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" =~ ^([A-Z0-9_]+)=(.*)$ ]]; then
      colour["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
    fi
  done <"$file"

  for key in BACKGROUND FOREGROUND ACCENT NORMAL_{0..7} BRIGHT_{0..7}; do
    val="${colour[$key]:-}"
    if [[ -z "$val" ]]; then
      printf 'palette: %s has no %s\n' "$file" "$key" >&2
      return 1
    fi
    if [[ ! "$val" =~ ^[0-9a-fA-F]{6}$ ]]; then
      printf 'palette: %s has invalid %s (%s)\n' "$file" "$key" "$val" >&2
      return 1
    fi
  done

  for key in BACKGROUND FOREGROUND ACCENT; do
    printf '%s=%s\n' "$key" "${colour[$key],,}"
  done
  for i in {0..7}; do
    printf 'NORMAL_%d=%s\n' "$i" "${colour[NORMAL_$i],,}"
  done
  for i in {0..7}; do
    printf 'BRIGHT_%d=%s\n' "$i" "${colour[BRIGHT_$i],,}"
  done
}
