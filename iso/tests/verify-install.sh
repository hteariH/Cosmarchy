#!/bin/bash

# Offline verification of an installed Cosmarchy system.
#
# Runs on the CI host against the installed disk image, mounted read-only at
# $ROOT. Every check here corresponds to a defect that reached a release or a
# contract of the COSMIC pivot.
#
# Usage: verify-install.sh /mnt/cosmarchy
set -uo pipefail

ROOT="${1:?usage: verify-install.sh <mounted-root>}"
USER_NAME="${COSMARCHY_TEST_USER:-citest}"
HOME_DIR="$ROOT/home/$USER_NAME"

pass=0
fail=0

ok() {
  printf '  \033[0;32mPASS\033[0m  %s\n' "$1"
  pass=$((pass + 1))
}

no() {
  printf '  \033[0;31mFAIL\033[0m  %s\n' "$1"
  [[ -n "${2:-}" ]] && printf '        %s\n' "$2"
  fail=$((fail + 1))
}

pkg_installed() {
  local pkg="$1"
  [[ -d "$ROOT/var/lib/pacman/local" ]] &&
    compgen -G "$ROOT/var/lib/pacman/local/${pkg}-[0-9]*" >/dev/null
}

echo "=== Offline verification of installed Cosmarchy system ==="
echo

# The installer puts /home and /var/log on their own btrfs subvolumes. If the
# caller mounted only @, those are empty directories and every check against
# them fails for a reason that has nothing to do with the install. Refuse to
# report that as a result.
if [[ ! -d "$HOME_DIR" ]]; then
  echo "  ABORT  \$HOME_DIR does not exist."
  echo "         The @home subvolume is probably not mounted; mount it before"
  echo "         running this, or every home check below is meaningless."
  exit 2
fi

if [[ ! -d "$ROOT/var/log" ]] || [[ -z "$(ls -A "$ROOT/var/log" 2>/dev/null)" ]]; then
  echo "  NOTE   $ROOT/var/log is empty - the @var_log subvolume may not be"
  echo "         mounted, so the install log will not be visible."
  echo
fi

# --- Display manager & greeter (cosmic-greeter / greetd) -------------------
# Note on symlinks: this image is mounted under $ROOT, so an absolute symlink
# inside it resolves against the *host* filesystem and -e reports false even
# when the link is perfectly correct. Test with -L and read the target instead
# of following it.
dm_unit="$ROOT/etc/systemd/system/display-manager.service"
if [[ -L "$dm_unit" || -f "$dm_unit" ]]; then
  dm_target="$(readlink "$dm_unit" 2>/dev/null || cat "$dm_unit" 2>/dev/null)"
  case "$dm_target" in
    *cosmic-greeter*) ok "cosmic-greeter.service is the enabled display manager" ;;
    *) no "display-manager is not cosmic-greeter" "resolves to ${dm_target:-unknown}" ;;
  esac
else
  no "No display manager enabled" "expected /etc/systemd/system/display-manager.service"
fi

gdm_units="$(find "$ROOT/etc/systemd/system" -maxdepth 3 -iname '*gdm*' 2>/dev/null || true)"
if [[ -z "$gdm_units" ]]; then
  ok "no GDM systemd unit enabled"
else
  no "stray GDM systemd unit present" "$gdm_units"
fi

# Verify gnome-keyring PAM integration on the PAM service greetd actually uses.
GREETER_CONF="$ROOT/etc/greetd/cosmic-greeter.toml"
if [[ -f "$GREETER_CONF" ]]; then
  pam_service="$(sed -nE 's/^[[:space:]]*service[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$GREETER_CONF" | head -n1)"
  pam_service="${pam_service:-greetd}"
  pam_file="$ROOT/etc/pam.d/$pam_service"
  if [[ -f "$pam_file" ]] && grep -q 'pam_gnome_keyring.so' "$pam_file"; then
    ok "keyring PAM integration present in /etc/pam.d/$pam_service"
  else
    no "keyring PAM line missing from /etc/pam.d/$pam_service" "expected pam_gnome_keyring.so"
  fi
else
  no "greetd config missing" "expected $GREETER_CONF"
fi

# --- Packages: COSMIC installed, GNOME shell/DM/compositor absent ----------
COSMIC_PACKAGES=(
  greetd
  cosmic-session cosmic-comp cosmic-greeter cosmic-settings cosmic-settings-daemon
  cosmic-panel cosmic-launcher cosmic-app-library cosmic-applets cosmic-notifications
  cosmic-osd cosmic-bg cosmic-idle cosmic-workspaces cosmic-randr cosmic-screenshot
  xdg-desktop-portal-cosmic cosmic-icon-theme cosmic-wallpapers cosmic-initial-setup
  cosmic-files cosmic-terminal cosmic-text-editor cosmic-player cosmic-store
)

missing_cosmic=()
for pkg in "${COSMIC_PACKAGES[@]}"; do
  pkg_installed "$pkg" || missing_cosmic+=("$pkg")
done
if ((${#missing_cosmic[@]} == 0)); then
  ok "all ${#COSMIC_PACKAGES[@]} COSMIC packages are installed"
else
  no "${#missing_cosmic[@]} COSMIC package(s) missing" "${missing_cosmic[*]}"
fi

stray_gnome=()
for pkg in gnome-shell gdm mutter; do
  pkg_installed "$pkg" && stray_gnome+=("$pkg")
done
if ((${#stray_gnome[@]} == 0)); then
  ok "no gnome-shell, gdm, or mutter packages installed"
else
  no "GNOME shell/DM/compositor packages still installed" "${stray_gnome[*]}"
fi

# --- KDE Connect & firewall rules (replaces GSConnect) ---------------------
if pkg_installed kdeconnect; then
  ok "kdeconnect is installed"
else
  no "kdeconnect is not installed"
fi
if grep -q '1714:1764' "$ROOT/etc/ufw/user.rules" 2>/dev/null; then
  ok "ufw allows KDE Connect's ports 1714-1764"
else
  no "ufw has no rule for KDE Connect's ports 1714-1764"
fi

# --- Regression: whisper.cpp vs whisper-cpp (aborted the whole install) ----
if [[ -e "$ROOT/usr/bin/whisper-cli" || -L "$ROOT/usr/bin/whisper-cli" ]]; then
  ok "whisper-cli present (Voxtype backend)"
else
  no "whisper-cli missing" "the whisper-cpp package did not install"
fi

# --- Desktop apps & developer tools ----------------------------------------
for pkg in chromium obs-studio libreoffice-fresh obsidian spotify-launcher mise; do
  if pkg_installed "$pkg"; then
    ok "$pkg is installed"
  else
    no "$pkg is not installed"
  fi
done
# Claude Code's native installer links ~/.local/bin/claude to its versions
# directory; the link is absolute, so test it with -L (see CLAUDE.md).
if [[ -L "$HOME_DIR/.local/bin/claude" || -x "$HOME_DIR/.local/bin/claude" ]]; then
  ok "Claude Code is installed"
else
  no "Claude Code is not installed" "expected $HOME_DIR/.local/bin/claude"
fi

# --- COSMIC configuration deployed byte-identical from default/cosmic/ -----
COSMARCHY_CHECKOUT="$HOME_DIR/.local/share/cosmarchy"
COSMIC_SRC="$COSMARCHY_CHECKOUT/default/cosmic"
COSMIC_DEST="$HOME_DIR/.config/cosmic"
if [[ -d "$COSMIC_SRC" ]]; then
  cosmic_checked=0
  cosmic_bad=()
  while IFS= read -r src_file; do
    [[ -n "$src_file" ]] || continue
    rel="${src_file#"$COSMIC_SRC/"}"
    dest_file="$COSMIC_DEST/$rel"
    cosmic_checked=$((cosmic_checked + 1))
    if [[ ! -f "$dest_file" ]]; then
      cosmic_bad+=("missing:$rel")
    elif ! cmp -s "$src_file" "$dest_file"; then
      cosmic_bad+=("differs:$rel")
    fi
  done < <(find "$COSMIC_SRC" -type f | sort)

  if ((cosmic_checked == 0)); then
    no "no files found under default/cosmic/"
  elif ((${#cosmic_bad[@]} == 0)); then
    ok "all $cosmic_checked default/cosmic/ file(s) deployed byte-identical into ~/.config/cosmic/"
  else
    no "COSMIC config deployment mismatch" "${cosmic_bad[*]}"
  fi
else
  no "default/cosmic/ missing in installed checkout" "expected $COSMIC_SRC"
fi

# --- Cosmarchy launcher plugin (pop-launcher) ------------------------------
if pkg_installed pop-launcher; then
  ok "pop-launcher is installed"
else
  no "pop-launcher is not installed"
fi

PLUGIN_LINK="$HOME_DIR/.local/share/pop-launcher/plugins/cosmarchy"
if [[ -L "$PLUGIN_LINK" ]]; then
  plugin_target="$(readlink "$PLUGIN_LINK")"
  case "$plugin_target" in
    */launcher/cosmarchy) ok "pop-launcher plugin symlink points at $plugin_target" ;;
    *) no "pop-launcher plugin symlink points at unexpected target" "$plugin_target" ;;
  esac
else
  no "pop-launcher plugin symlink missing" "expected symlink at $PLUGIN_LINK"
fi

if [[ -f "$COSMARCHY_CHECKOUT/launcher/cosmarchy/plugin.ron" ]]; then
  ok "launcher plugin.ron is present"
else
  no "launcher plugin.ron missing" "expected $COSMARCHY_CHECKOUT/launcher/cosmarchy/plugin.ron"
fi

if [[ -x "$COSMARCHY_CHECKOUT/launcher/cosmarchy/cosmarchy-launcher" ]]; then
  ok "cosmarchy-launcher plugin executable is present and +x"
else
  no "cosmarchy-launcher plugin missing or not executable" "expected $COSMARCHY_CHECKOUT/launcher/cosmarchy/cosmarchy-launcher"
fi

if [[ -f "$COSMARCHY_CHECKOUT/launcher/actions.tsv" ]]; then
  ok "launcher actions.tsv catalog is present"
else
  no "launcher actions.tsv missing" "expected $COSMARCHY_CHECKOUT/launcher/actions.tsv"
fi

CUSTOM_SHORTCUTS="$COSMIC_DEST/com.system76.CosmicSettings.Shortcuts/v1/custom"
if [[ -f "$CUSTOM_SHORTCUTS" ]] &&
  grep -qF 'Spawn("cosmic-launcher input \"c \"")' "$CUSTOM_SHORTCUTS" &&
  grep -qF 'Spawn("cosmic-launcher input \"c key \"")' "$CUSTOM_SHORTCUTS" &&
  grep -qF 'Spawn("cosmic-launcher input \"c man \"")' "$CUSTOM_SHORTCUTS"; then
  ok "custom shortcuts spawn cosmic-launcher input for c , c key , and c man "
else
  no "custom shortcuts missing cosmic-launcher input spawns" "$(cat "$CUSTOM_SHORTCUTS" 2>/dev/null || echo missing)"
fi

# --- Session-critical symlinks and executable bits -------------------------
missing_links=()
for cmd in cosmarchy cosmarchy-first-run cosmarchy-menu cosmarchy-keybindings \
  cosmarchy-manual cosmarchy-tiling cosmarchy-capture cosmarchy-migrate \
  cosmarchy-power cosmarchy-settings \
  cosmarchy-windows cosmarchy-snapshot-create cosmarchy-snapshot-list \
  cosmarchy-snapshot-restore cosmarchy-snapshot-notify; do
  link="$ROOT/usr/local/bin/$cmd"
  [[ -L "$link" || -f "$link" ]] || missing_links+=("$cmd")
done
if ((${#missing_links[@]} == 0)); then
  ok "all session-critical commands are in /usr/local/bin"
else
  no "commands missing from /usr/local/bin" "${missing_links[*]}"
fi

non_exec_bin=()
for cmd in "$COSMARCHY_CHECKOUT"/bin/cosmarchy*; do
  [[ -f "$cmd" ]] || continue
  [[ -x "$cmd" ]] || non_exec_bin+=("$(basename "$cmd")")
done
if ((${#non_exec_bin[@]} == 0)); then
  ok "all cosmarchy bin/ scripts carry the executable bit"
else
  no "non-executable scripts in bin/" "${non_exec_bin[*]}"
fi

# --- Rename completeness: no leftover gnomarchy names ----------------------
stray_bin="$(find "$ROOT/usr/local/bin" -maxdepth 1 -iname '*gnomarchy*' 2>/dev/null || true)"
if [[ -z "$stray_bin" ]]; then
  ok "no gnomarchy symlinks in /usr/local/bin"
else
  no "leftover gnomarchy entries in /usr/local/bin" "$stray_bin"
fi

stray_home="$(find "$HOME_DIR/.local" "$HOME_DIR/.config" -maxdepth 3 -iname '*gnomarchy*' 2>/dev/null || true)"
if [[ -z "$stray_home" ]]; then
  ok "no gnomarchy paths under \$HOME"
else
  no "leftover gnomarchy paths under \$HOME" "$stray_home"
fi

# --- Removed packages & commands -------------------------------------------
for pkg in alacritty qemu-desktop edk2-ovmf swtpm; do
  if pkg_installed "$pkg"; then
    no "$pkg is installed" "it was dropped from cosmarchy-base.packages"
  else
    ok "$pkg is not installed"
  fi
done

for removed_cmd in cosmarchy-screensaver cosmarchy-theme-set cosmarchy-backgrounds cosmarchy-keymap; do
  if [[ -e "$ROOT/usr/local/bin/$removed_cmd" || -L "$ROOT/usr/local/bin/$removed_cmd" ]]; then
    no "$removed_cmd is still published" "this command was removed"
  else
    ok "no $removed_cmd command"
  fi
done

# --- Regression: ISO deployed without .git, so updates were impossible -----
if [[ -d "$COSMARCHY_CHECKOUT/.git" ]]; then
  ok "Cosmarchy checkout has a git repository (updates possible)"
elif [[ -d "$COSMARCHY_CHECKOUT" ]]; then
  no "no .git in ~/.local/share/cosmarchy" \
    "checkout exists but is not a repository; contains: $(ls "$COSMARCHY_CHECKOUT" | tr '\n' ' ')"
else
  no "no Cosmarchy checkout at all" "expected $COSMARCHY_CHECKOUT"
fi

# --- Unattended initial-setup bypass marker --------------------------------
SETUP_MARKER="$HOME_DIR/.config/cosmic-initial-setup-done"
if [[ -f "$SETUP_MARKER" ]]; then
  home_owner="$(stat -c '%u:%g' "$HOME_DIR")"
  marker_owner="$(stat -c '%u:%g' "$SETUP_MARKER")"
  if [[ "$marker_owner" == "$home_owner" ]]; then
    ok "unattended install created ~/.config/cosmic-initial-setup-done owned by user ($marker_owner)"
  else
    no "~/.config/cosmic-initial-setup-done has wrong owner" "expected $home_owner, got $marker_owner"
  fi
else
  no "missing ~/.config/cosmic-initial-setup-done" "cosmic-initial-setup will block unattended session boot"
fi

# --- Windows apps: WinBoat, opt-in -----------------------------------------
WINDOWS_CMD="$COSMARCHY_CHECKOUT/bin/cosmarchy-windows"
if [[ -L "$ROOT/usr/local/bin/cosmarchy-windows" ]] && grep -q 'winboat-bin' "$WINDOWS_CMD"; then
  ok "cosmarchy windows is the WinBoat installer"
else
  no "cosmarchy windows is not the WinBoat installer" "$WINDOWS_CMD"
fi

# --- Regression: two identical Brave entries in the launcher ---------------
alias_file="$ROOT/usr/share/applications/brave-browser.desktop"
if [[ -f "$alias_file" ]]; then
  grep -q '^NoDisplay=true' "$alias_file" &&
    ok "Brave compatibility alias is hidden from the launcher" ||
    no "brave-browser.desktop is visible" "this shows a duplicate Brave icon"
else
  ok "no Brave alias desktop entry to duplicate"
fi

visible_browsers=0
for f in "$ROOT/usr/share/applications"/*brave*.desktop; do
  [[ -f "$f" ]] || continue
  grep -q '^NoDisplay=true' "$f" || visible_browsers=$((visible_browsers + 1))
done
((visible_browsers <= 1)) &&
  ok "exactly $visible_browsers visible Brave entry" ||
  no "$visible_browsers visible Brave entries" "the launcher will show duplicates"

# --- Regression: Brave desktop entry Exec and icon -------------------------
BRAVE_DESKTOP="$ROOT/usr/share/applications/brave-origin.desktop"
if [[ -f "$BRAVE_DESKTOP" ]]; then
  exec_target="$(awk -F= '/^Exec=/ {print $2; exit}' "$BRAVE_DESKTOP" | awk '{print $1}')"
  if [[ -n "$exec_target" ]]; then
    resolved="$ROOT${exec_target}"
    if [[ -L "$resolved" ]]; then
      link_dest="$(readlink "$resolved")"
      resolved="$ROOT${link_dest}"
    fi
    if [[ -f "$resolved" ]]; then
      ok "Brave desktop entry points at a real binary ($(basename "$exec_target"))"
    else
      no "Brave Exec target does not exist" "$exec_target -> ${resolved#"$ROOT"}"
    fi
  fi

  icon_name="$(awk -F= '/^Icon=/ {print $2; exit}' "$BRAVE_DESKTOP")"
  icon_sizes=0
  for dir in "$ROOT/usr/share/icons/hicolor"/*/apps; do
    [[ -f "$dir/$icon_name.png" ]] && icon_sizes=$((icon_sizes + 1))
  done
  if ((icon_sizes >= 4)); then
    ok "Brave icon installed in $icon_sizes sizes"
  elif ((icon_sizes > 0)); then
    no "Brave icon installed in only $icon_sizes size(s)" "the launcher will scale it badly"
  else
    no "Brave icon '$icon_name' is not installed" "the launcher shows a broken icon"
  fi
fi

# --- Regression: Brave binaries extracted without the executable bit -------
BRAVE_DIR="$ROOT/opt/brave-origin"
if [[ -d "$BRAVE_DIR" ]]; then
  non_exec=()
  for helper in brave chrome_crashpad_handler chrome-sandbox; do
    bin="$BRAVE_DIR/$helper"
    [[ -f "$bin" ]] || continue
    [[ -x "$bin" ]] || non_exec+=("$helper")
  done
  if ((${#non_exec[@]} == 0)); then
    ok "Brave binaries carry the executable bit"
  else
    no "${#non_exec[@]} Brave binary/binaries not executable" "${non_exec[*]}"
  fi

  if [[ -f "$BRAVE_DIR/chrome-sandbox" ]]; then
    perms="$(stat -c '%a' "$BRAVE_DIR/chrome-sandbox" 2>/dev/null)"
    [[ "$perms" == "4755" ]] &&
      ok "chrome-sandbox is setuid root" ||
      no "chrome-sandbox has mode $perms" "expected 4755"
  fi
else
  no "Brave Origin not installed" "expected $BRAVE_DIR"
fi

# --- Tool configs ----------------------------------------------------------
[[ -f "$HOME_DIR/.config/nvim/lua/config/lazy.lua" ]] &&
  ok "LazyVim bootstrap deployed" ||
  no "LazyVim bootstrap missing"

# --- Boot: Limine, initramfs and snapshots ---------------------------------
BOOT_DIR="$ROOT/boot"
LIMINE_CONF="$BOOT_DIR/limine.conf"
CMDLINE_FILE="$ROOT/etc/kernel/cmdline"
b2() { b2sum "$1" | cut -d' ' -f1; }

cmdline=""
if [[ -f "$CMDLINE_FILE" ]]; then
  cmdline="$(<"$CMDLINE_FILE")"
  ok "/etc/kernel/cmdline exists"
else
  no "no /etc/kernel/cmdline" "cosmarchy-boot has nothing to build the menu from"
fi

if [[ -f "$LIMINE_CONF" ]]; then
  refs=0
  bad=0
  while read -r path hash; do
    refs=$((refs + 1))
    if [[ ! -f "$BOOT_DIR$path" ]]; then
      no "limine.conf points at a missing file" "$path"
      bad=$((bad + 1))
    elif [[ "$(b2 "$BOOT_DIR$path")" != "$hash" ]]; then
      no "limine.conf hash does not match" "$path"
      bad=$((bad + 1))
    fi
  done < <(sed -nE 's/^[[:space:]]*(kernel_path|module_path): boot\(\):([^#]+)#([0-9a-f]{128})$/\2 \3/p' "$LIMINE_CONF")
  unhashed="$(grep -cE '^[[:space:]]*(kernel_path|module_path): boot\(\):[^#]*$' "$LIMINE_CONF")"
  if ((refs > 0 && bad == 0 && unhashed == 0)); then
    ok "limine.conf: all $refs boot files exist and match their blake2b hashes"
  elif ((refs == 0)); then
    no "limine.conf has no hashed kernel or initramfs paths"
  elif ((unhashed > 0)); then
    no "limine.conf has $unhashed boot paths without a hash"
  fi
  grep -qx 'default_entry: Cosmarchy/linux' "$LIMINE_CONF" &&
    ok "the menu defaults to Cosmarchy/linux" || no "the menu does not default to Cosmarchy/linux"
  grep -qx 'interface_branding: Cosmarchy' "$LIMINE_CONF" && grep -q '^term_palette: ' "$LIMINE_CONF" &&
    ok "the menu carries the fixed COSMIC Dark palette" || no "no palette in limine.conf"
  [[ -n "$cmdline" ]] && grep -qxF "    kernel_cmdline: $cmdline" "$LIMINE_CONF" &&
    ok "the kernel entry boots /etc/kernel/cmdline" || no "no entry boots /etc/kernel/cmdline"
  fs_uuid="$(findmnt -no UUID --target "$ROOT")"
  [[ -n "$fs_uuid" && " $cmdline " == *" root=UUID=$fs_uuid "* ]] &&
    ok "root=UUID matches the installed Btrfs" || no "root=UUID does not match the Btrfs UUID" "fs: $fs_uuid, cmdline: $cmdline"
else
  no "no limine.conf on the ESP"
fi

for efi in EFI/BOOT/BOOTX64.EFI EFI/limine/BOOTX64.EFI; do
  if [[ -f "$BOOT_DIR/$efi" && "$(b2 "$BOOT_DIR/$efi")" == "$(b2 "$ROOT/usr/share/limine/BOOTX64.EFI")" ]]; then
    ok "$efi is the installed Limine"
  else
    no "$efi is missing or not the installed Limine"
  fi
done
if [[ -f "$BOOT_DIR/limine-bios.sys" && "$(b2 "$BOOT_DIR/limine-bios.sys")" == "$(b2 "$ROOT/usr/share/limine/limine-bios.sys")" ]]; then
  ok "limine-bios.sys is on the ESP"
else
  no "limine-bios.sys missing from the ESP"
fi
if [[ -n "${COSMARCHY_TEST_DISK:-}" ]]; then
  if (($(head -c 440 "$COSMARCHY_TEST_DISK" | tr -d '\0' | wc -c) > 0)); then
    ok "the MBR carries boot code (limine bios-install ran)"
  else
    no "the MBR boot code is empty" "limine bios-install never ran on $COSMARCHY_TEST_DISK"
  fi
fi
esp_dev="$(findmnt -no SOURCE --target "$BOOT_DIR")"
if [[ -n "$esp_dev" ]] && (($(blockdev --getsize64 "$esp_dev") >= 4 * 1024 * 1024 * 1024)); then
  ok "the ESP is at least 4 GiB"
else
  no "the ESP is smaller than 4 GiB" "$esp_dev"
fi

DROPIN="$ROOT/etc/mkinitcpio.conf.d/cosmarchy.conf"
if [[ -f "$DROPIN" ]]; then
  hooks=" $(sed -n 's/^HOOKS=(\(.*\))$/\1/p' "$DROPIN") "
  missing=()
  for h in systemd plymouth sd-vconsole cosmarchy-overlay; do
    [[ "$hooks" == *" $h "* ]] || missing+=("$h")
  done
  ((${#missing[@]} == 0)) && ok "initramfs HOOKS include systemd, plymouth, sd-vconsole, cosmarchy-overlay" ||
    no "initramfs HOOKS lack: ${missing[*]}" "$hooks"
  [[ "$hooks" == *" udev "* || "$hooks" == *" encrypt "* ]] &&
    no "busybox hooks in a systemd initramfs" "$hooks"
  if [[ "${COSMARCHY_TEST_ENCRYPT:-n}" == y ]]; then
    [[ "$hooks" == *" sd-encrypt "* ]] && ok "sd-encrypt is in HOOKS" || no "an encrypted install without sd-encrypt"
  else
    [[ "$hooks" == *" sd-encrypt "* ]] &&
      no "sd-encrypt in HOOKS on a plain install" "$hooks" || ok "no sd-encrypt in HOOKS on a plain install"
  fi
else
  no "no /etc/mkinitcpio.conf.d/cosmarchy.conf"
fi
[[ -f "$ROOT/etc/initcpio/install/cosmarchy-overlay" ]] &&
  ok "the cosmarchy-overlay initcpio hook is installed" || no "no cosmarchy-overlay initcpio hook"
grep -q 'subvolid=' "$ROOT/etc/fstab" &&
  no "fstab pins subvolid=" "snapshots and a restored @ cannot mount" || ok "fstab mounts by subvolume name only"

SNAPCFG="$ROOT/etc/snapper/configs/root"
if [[ -f "$SNAPCFG" ]]; then
  for kv in 'TIMELINE_CREATE="no"' 'NUMBER_LIMIT="10"' 'ALLOW_GROUPS="wheel"'; do
    grep -qxF "$kv" "$SNAPCFG" && ok "snapper root config: $kv" || no "snapper root config lacks $kv"
  done
else
  no "no snapper root config" "snapper-init never ran"
fi
grep -qE '^SNAPPER_CONFIGS="(.* )?root( .*)?"$' "$ROOT/etc/conf.d/snapper" &&
  ok "SNAPPER_CONFIGS lists root" || no "SNAPPER_CONFIGS does not list root"
[[ -L "$ROOT/etc/systemd/system/timers.target.wants/snapper-cleanup.timer" ]] &&
  ok "snapper-cleanup.timer is enabled" || no "snapper-cleanup.timer is not enabled"
[[ -L "$ROOT/etc/systemd/system/timers.target.wants/snapper-timeline.timer" ]] &&
  no "snapper-timeline.timer is enabled" "timeline snapshots are off by design"
[[ -s "$ROOT/etc/cosmarchy/boot-theme.conf" ]] &&
  ok "fixed Limine palette deployed to /etc/cosmarchy/boot-theme.conf" || no "no /etc/cosmarchy/boot-theme.conf"
[[ -x "$ROOT/usr/lib/snapper/plugins/50-cosmarchy-boot" ]] &&
  ok "the snapper plugin is installed" || no "no executable snapper plugin"
for hook in 00-cosmarchy-guard.hook 95-cosmarchy-boot.hook 95-cosmarchy-limine.hook; do
  [[ -f "$ROOT/etc/pacman.d/hooks/$hook" ]] && ok "pacman hook $hook" || no "no pacman hook $hook"
done
[[ -x "$ROOT/etc/initcpio/post/cosmarchy-boot" ]] &&
  ok "the mkinitcpio post hook is installed" || no "no executable mkinitcpio post hook"
pkg_installed snap-pac &&
  ok "snap-pac is installed" || no "snap-pac is not installed"
if grep -q '<description>Cosmarchy installed</description>' "$ROOT/.snapshots/1/info.xml" 2>/dev/null; then
  ok "snapshot 1 \"Cosmarchy installed\" exists"
else
  no "no snapshot 1 \"Cosmarchy installed\""
fi
[[ -f "$BOOT_DIR/cosmarchy/entries/1.conf" ]] && grep -q '^///1 | ' "$LIMINE_CONF" &&
  ok "snapshot 1 is in the boot menu" || no "snapshot 1 is not in the boot menu"

# --- The installer's answers ------------------------------------------------
if [[ -n "${CI:-}" && -z "${COSMARCHY_TEST_HOSTNAME:-}" ]]; then
  no "COSMARCHY_TEST_* variables did not reach the script" "CI is set but COSMARCHY_TEST_HOSTNAME is not; the environment was dropped on the way in"
fi
if [[ -n "${COSMARCHY_TEST_HOSTNAME:-}" ]]; then
  [[ "$(<"$ROOT/etc/hostname")" == "$COSMARCHY_TEST_HOSTNAME" ]] &&
    ok "hostname is $COSMARCHY_TEST_HOSTNAME" || no "hostname is not $COSMARCHY_TEST_HOSTNAME" "$(<"$ROOT/etc/hostname")"
fi
if [[ -n "${COSMARCHY_TEST_TIMEZONE:-}" ]]; then
  tz_link="$(readlink "$ROOT/etc/localtime")"
  [[ -L "$ROOT/etc/localtime" && "$tz_link" == */zoneinfo/$COSMARCHY_TEST_TIMEZONE ]] &&
    ok "timezone is $COSMARCHY_TEST_TIMEZONE" || no "timezone is not $COSMARCHY_TEST_TIMEZONE" "$tz_link"
fi
if [[ -n "${COSMARCHY_TEST_KEYMAP:-}" ]]; then
  # shellcheck source=../installer/lib/form.sh
  source "$(dirname "$0")/../installer/lib/form.sh"
  if keymap_load "$COSMARCHY_TEST_KEYMAP"; then
    grep -qx "KEYMAP=$KB_CONSOLE_KEYMAP" "$ROOT/etc/vconsole.conf" &&
      ok "console keymap is $KB_CONSOLE_KEYMAP" || no "console keymap is not $KB_CONSOLE_KEYMAP"
    grep -qF "Option \"XkbLayout\" \"$KB_XKB_LAYOUT\"" "$ROOT/etc/X11/xorg.conf.d/00-keyboard.conf" &&
      ok "X11 layout is $KB_XKB_LAYOUT" || no "X11 layout is not $KB_XKB_LAYOUT"
    grep -qx "XKB_LAYOUT=$KB_XKB_LAYOUT" "$ROOT/etc/cosmarchy/keyboard.conf" &&
      ok "keyboard.conf records $KB_XKB_LAYOUT" || no "keyboard.conf does not name $KB_XKB_LAYOUT"
    XKB_FILE="$COSMIC_DEST/com.system76.CosmicComp/v1/xkb_config"
    if [[ "$KB_LATIN" == no ]]; then
      expected_xkb="layout: \"us,${KB_XKB_LAYOUT}\""
    else
      expected_xkb="layout: \"${KB_XKB_LAYOUT}\""
    fi
    if [[ -f "$XKB_FILE" ]] && grep -qF "$expected_xkb" "$XKB_FILE"; then
      ok "COSMIC xkb_config sets $expected_xkb"
    else
      no "COSMIC xkb_config does not contain $expected_xkb" "$(cat "$XKB_FILE" 2>/dev/null || echo missing)"
    fi
  else
    no "COSMARCHY_TEST_KEYMAP $COSMARCHY_TEST_KEYMAP is not in keymaps.tsv"
  fi
fi
grep -q 'Installation complete' "$ROOT/var/log/cosmarchy-installer.log" &&
  ok "the installer log is on the target" || no "no complete installer log at /var/log/cosmarchy-installer.log"

if [[ "${COSMARCHY_TEST_ENCRYPT:-n}" != y ]]; then
  [[ "$cmdline" == *"rd.luks.name="* ]] &&
    no "rd.luks.name on a plain install" "$cmdline" || ok "no rd.luks.name on a plain install"
fi
if [[ "${COSMARCHY_TEST_ENCRYPT:-n}" == y ]]; then
  if [[ -n "${COSMARCHY_TEST_LUKS_DEV:-}" ]]; then
    luks_uuid="$(blkid -s UUID -o value "$COSMARCHY_TEST_LUKS_DEV")"
    [[ -n "$luks_uuid" && " $cmdline " == *" rd.luks.name=$luks_uuid=cryptroot "* ]] &&
      ok "rd.luks.name opens the LUKS partition" || no "rd.luks.name does not name $luks_uuid" "$cmdline"
  else
    echo "  SKIP  rd.luks.name check: COSMARCHY_TEST_LUKS_DEV is not set"
  fi
  if [[ -f "$ROOT/etc/crypttab" ]] && grep -q '^cryptroot' "$ROOT/etc/crypttab"; then
    no "crypttab also opens cryptroot" "the root is opened from the command line"
  else
    ok "crypttab does not compete with rd.luks.name"
  fi
  if [[ -f "$GREETER_CONF" ]] &&
    grep -q '^\[initial_session\]' "$GREETER_CONF" &&
    grep -q 'command = "start-cosmic"' "$GREETER_CONF" &&
    grep -q "user = \"$USER_NAME\"" "$GREETER_CONF"; then
    ok "greetd [initial_session] autologin configured on the encrypted install"
  else
    no "greetd [initial_session] autologin not configured on the encrypted install"
  fi
fi

echo
echo "=== $pass passed, $fail failed ==="
((fail == 0))
