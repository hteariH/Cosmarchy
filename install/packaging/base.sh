#!/bin/bash

cosmarchy_header "Installing Base Cosmarchy Packages"

package_file="$COSMARCHY_INSTALL/cosmarchy-base.packages"

# Parse packages, removing comments and blank lines
mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^[[:space:]]*$' | tr -d '\r')

# Partition the list against the sync databases first.
#
# `pacman -S` is all-or-nothing: a single unknown name aborts the whole
# transaction, which under `set -e` kills the installer and strands a
# half-installed machine. One typo must not cost the other 100+ packages, so
# unresolvable names are reported and skipped instead.
declare -A available_index=()
while read -r name; do
  [[ -n "$name" ]] && available_index["$name"]=1
done < <(pacman -Slq 2>/dev/null)

# If the sync database could not be read at all, do not "helpfully" declare
# every package missing: fall back to handing the full list to pacman so it
# reports the real problem itself.
if ((${#available_index[@]} == 0)); then
  cosmarchy_warn "Could not read the package databases; installing without pre-validation."
  echo "Installing ${#packages[@]} core packages via pacman..."
  sudo pacman -S --noconfirm --needed "${packages[@]}"
  cosmarchy_step "Core packages successfully installed"
  return 0 2>/dev/null || exit 0
fi

resolved=()
unresolved=()
for pkg in "${packages[@]}"; do
  if [[ -n "${available_index[$pkg]:-}" ]]; then
    resolved+=("$pkg")
  elif pacman -Si "$pkg" >/dev/null 2>&1 || pacman -Sg "$pkg" >/dev/null 2>&1; then
    # Covers virtual packages, provides, and group names.
    resolved+=("$pkg")
  else
    unresolved+=("$pkg")
  fi
done

if ((${#unresolved[@]} > 0)); then
  cosmarchy_warn "${#unresolved[@]} package(s) not found in any configured repository:"
  for pkg in "${unresolved[@]}"; do
    cosmarchy_substep "$pkg"
  done
  cosmarchy_warn "Continuing without them; dependent features may be unavailable."
fi

if ((${#resolved[@]} == 0)); then
  cosmarchy_error "No installable packages resolved - check the mirrorlist and try again."
  exit 1
fi

echo "Installing ${#resolved[@]} core packages via pacman..."
sudo pacman -S --noconfirm --needed "${resolved[@]}"

cosmarchy_step "Core packages successfully installed"
