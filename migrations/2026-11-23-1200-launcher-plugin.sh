#!/bin/bash

# Migration: install Cosmarchy pop-launcher plugin symlink and switch the three
# unmodified v0.1.0 cosmic-term shortcuts to cosmic-launcher input spawns.
#
# Idempotent: safe to run on a machine in any state. User-rebound lines in
# custom shortcuts are left untouched.
set -eEo pipefail

COSMARCHY_PATH="${COSMARCHY_PATH:-$HOME/.local/share/cosmarchy}"
PLUGIN_SRC="$COSMARCHY_PATH/launcher/cosmarchy"
PLUGINS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pop-launcher/plugins"
PLUGIN_LINK="$PLUGINS_DIR/cosmarchy"

if [[ ! -d "$PLUGIN_SRC" ]]; then
  echo "Launcher plugin source not found at $PLUGIN_SRC" >&2
  exit 1
fi

chmod +x "$PLUGIN_SRC/cosmarchy-launcher"
mkdir -p "$PLUGINS_DIR"
ln -sfn "$PLUGIN_SRC" "$PLUGIN_LINK"

CUSTOM_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
if [[ ! -f "$CUSTOM_FILE" ]]; then
  exit 0
fi

OLD_MENU='(modifiers: [Super, Alt], key: "space", description: Some("Cosmarchy Menu")): Spawn("cosmic-term -e cosmarchy-menu"),'
NEW_MENU='(modifiers: [Super, Alt], key: "space", description: Some("Cosmarchy Menu")): Spawn("cosmic-launcher input \"c \""),'

OLD_KEYS='(modifiers: [Super, Alt], key: "slash", description: Some("Cosmarchy Keybindings")): Spawn("cosmic-term -e cosmarchy-keybindings"),'
NEW_KEYS='(modifiers: [Super, Alt], key: "slash", description: Some("Cosmarchy Keybindings")): Spawn("cosmic-launcher input \"c key \""),'

OLD_MAN='(modifiers: [Super, Alt], key: "m", description: Some("Cosmarchy Manual")): Spawn("cosmic-term -e cosmarchy-manual"),'
NEW_MAN='(modifiers: [Super, Alt], key: "m", description: Some("Cosmarchy Manual")): Spawn("cosmic-launcher input \"c man \""),'

changed=0
out_lines=()
while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="${line#"${line%%[![:space:]]*}"}"
  indent="${line%"$trimmed"}"
  case "$trimmed" in
    "$OLD_MENU")
      out_lines+=("${indent}${NEW_MENU}")
      changed=1
      ;;
    "$OLD_KEYS")
      out_lines+=("${indent}${NEW_KEYS}")
      changed=1
      ;;
    "$OLD_MAN")
      out_lines+=("${indent}${NEW_MAN}")
      changed=1
      ;;
    *)
      out_lines+=("$line")
      ;;
  esac
done < "$CUSTOM_FILE"

if ((changed)); then
  target_dir="$(dirname "$CUSTOM_FILE")"
  tmp="$(mktemp "$target_dir/.custom.XXXXXX")"
  if ! printf '%s\n' "${out_lines[@]}" > "$tmp" || ! chmod 644 "$tmp" || ! mv -f -- "$tmp" "$CUSTOM_FILE"; then
    rm -f -- "$tmp"
    exit 1
  fi
fi
