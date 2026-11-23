#!/bin/bash
# Installer field rules, shared by the interactive form and the unattended
# answers. No UI and no side effects: iso/tests/test-installer-validate.sh runs
# them directly.

INSTALLER_LIB="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_KEYMAPS="$INSTALLER_LIB/keymaps.tsv"
INSTALLER_ZONEINFO="${INSTALLER_ZONEINFO:-/usr/share/zoneinfo}"

valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ && "$1" != root ]]; }

# One RFC 1123 label: letters, digits and inner hyphens, at most 63.
valid_hostname() { [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]; }

valid_timezone() {
  [[ "$1" =~ ^[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)*$ && -f "$INSTALLER_ZONEINFO/$1" ]]
}

# keymap_fields ID — the table row as KEY=value lines ('-' becomes empty).
keymap_fields() {
  awk -F'\t' -v id="$1" '
    !/^#/ && $1 == id {
      for (i = 3; i <= 5; i++) if ($i == "-") $i = ""
      printf "XKB_LAYOUT=%s\nXKB_VARIANT=%s\nCONSOLE_KEYMAP=%s\nCONSOLE_FONT=%s\nLATIN=%s\nLABEL=%s\n",
        $2, $3, $4, $5, $6, $7
      found = 1
      exit
    }
    END { exit !found }' "$INSTALLER_KEYMAPS"
}

# keymap_load ID — sets KB_XKB_LAYOUT, KB_XKB_VARIANT, KB_CONSOLE_KEYMAP,
# KB_CONSOLE_FONT, KB_LATIN and KB_LABEL.
keymap_load() {
  local fields line
  fields="$(keymap_fields "$1")" || return 1
  while IFS= read -r line; do
    printf -v "KB_${line%%=*}" '%s' "${line#*=}"
  done <<<"$fields"
}

# Lines for gum filter: "Label  [id]".
keymap_menu() {
  awk -F'\t' '!/^#/ && NF >= 7 { printf "%s  [%s]\n", $7, $1 }' "$INSTALLER_KEYMAPS"
}

keymap_id_from_menu() {
  local re='\[([^]]+)\]$'
  [[ "$1" =~ $re ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

# installer_check_answers — validates the COSMARCHY_* answers read from
# cosmarchy-unattended.conf and fills the defaults. Prints every problem, not
# just the first, because each CI round trip is long.
installer_check_answers() {
  local -a problems=()
  COSMARCHY_FULLNAME="${COSMARCHY_FULLNAME:-}"
  COSMARCHY_HOSTNAME="${COSMARCHY_HOSTNAME:-cosmarchy}"
  COSMARCHY_TIMEZONE="${COSMARCHY_TIMEZONE:-UTC}"
  COSMARCHY_KEYMAP="${COSMARCHY_KEYMAP:-us}"
  COSMARCHY_ENCRYPT="${COSMARCHY_ENCRYPT:-n}"
  COSMARCHY_DISK_PASSWORD="${COSMARCHY_DISK_PASSWORD:-${COSMARCHY_PASSWORD:-}}"

  [[ -n "${COSMARCHY_DISK:-}" ]] || problems+=("COSMARCHY_DISK is not set")
  valid_username "${COSMARCHY_USERNAME:-}" ||
    problems+=("COSMARCHY_USERNAME '${COSMARCHY_USERNAME:-}' is not a valid username")
  [[ -n "${COSMARCHY_PASSWORD:-}" ]] || problems+=("COSMARCHY_PASSWORD is not set")
  valid_hostname "$COSMARCHY_HOSTNAME" || problems+=("COSMARCHY_HOSTNAME '$COSMARCHY_HOSTNAME' is not a valid hostname")
  valid_timezone "$COSMARCHY_TIMEZONE" || problems+=("COSMARCHY_TIMEZONE '$COSMARCHY_TIMEZONE' is not a timezone")
  keymap_fields "$COSMARCHY_KEYMAP" >/dev/null ||
    problems+=("COSMARCHY_KEYMAP '$COSMARCHY_KEYMAP' is not in keymaps.tsv")
  case "${COSMARCHY_ENCRYPT,,}" in
    y | yes) COSMARCHY_ENCRYPT=y ;;
    n | no) COSMARCHY_ENCRYPT=n ;;
    *) problems+=("COSMARCHY_ENCRYPT must be y or n, got '$COSMARCHY_ENCRYPT'") ;;
  esac

  ((${#problems[@]} == 0)) && return 0
  printf 'answers: %s\n' "${problems[@]}" >&2
  return 1
}
