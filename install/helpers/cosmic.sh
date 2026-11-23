#!/bin/bash

# Helpers for writing cosmic-config RON files atomically.
#
# cosmic-config stores one key per file under:
#   ${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/<component-id>/v1/<key>
# Plain files written inside arch-chroot work without a D-Bus session bus,
# so COSMIC desktop configuration does not need a first-run autostart pass.

# Atomically write a single cosmic-config key file.
# Usage: cosmarchy_cosmic_write <component-id> <key> <ron-value>
cosmarchy_cosmic_write() {
  local component="$1"
  local key="$2"
  local value="$3"
  local target_root="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic"
  local target_dir="$target_root/$component/v1"
  local dest="$target_dir/$key"
  local tmp

  mkdir -p "$target_dir"
  tmp="$(mktemp "$target_dir/.${key}.XXXXXX")"
  if ! printf '%s\n' "$value" > "$tmp" || ! chmod 644 "$tmp" || ! mv -f -- "$tmp" "$dest"; then
    rm -f -- "$tmp"
    return 1
  fi
}

# Atomically deploy the default/cosmic/ tree into $HOME/.config/cosmic/.
# Usage: cosmarchy_cosmic_deploy [source-dir] [target-dir]
cosmarchy_cosmic_deploy() {
  local src_root="${1:-${COSMARCHY_PATH:-$HOME/.local/share/cosmarchy}/default/cosmic}"
  local dest_root="${2:-${XDG_CONFIG_HOME:-$HOME/.config}/cosmic}"

  if [[ ! -d "$src_root" ]]; then
    echo "COSMIC config source directory not found: $src_root" >&2
    return 1
  fi

  local file rel dest dest_dir tmp count=0
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    rel="${file#"$src_root/"}"
    dest="$dest_root/$rel"
    dest_dir="$(dirname "$dest")"

    mkdir -p "$dest_dir"
    tmp="$(mktemp "$dest_dir/.$(basename "$dest").XXXXXX")"
    if ! cp -- "$file" "$tmp" || ! chmod 644 "$tmp" || ! mv -f -- "$tmp" "$dest"; then
      rm -f -- "$tmp"
      return 1
    fi
    count=$((count + 1))
  done < <(find "$src_root" -type f | sort)

  if (( count == 0 )); then
    echo "No COSMIC config files found under $src_root" >&2
    return 1
  fi
}
