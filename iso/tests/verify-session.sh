#!/bin/bash

# In-guest COSMIC session verification.
#
# Runs inside the installed system's live COSMIC autologin session via XDG
# autostart. Verifies what cannot be checked offline: COSMIC daemons running,
# shortcut RON parsing clean in journal, no overlap with COSMIC defaults,
# autotile and xkb_config active, xdg-desktop-portal-cosmic on D-Bus, snapper +
# snap-pac + Limine snapshots, WinBoat prerequisites, and the third-boot
# snapshot restore flow.
#
# Writes its report to ~/.local/state/cosmarchy/verify/<mode>.txt and powers
# off, so CI reads the outcome from the disk image rather than the serial
# console. /home is its own subvolume: the report survives a snapshot boot,
# whose root is a tmpfs overlay that /var/tmp used to vanish with.
trace() {
  # logger may not exist in minimal environments; trace is best-effort.
  logger -t cosmarchy-verify -- "$*" 2>/dev/null || true
}

trace "verify-session started as $(whoami), session=${XDG_SESSION_TYPE:-unknown}"

MODE=session
SNAPSHOT_BOOTED=""
read -ra cmdline_words </proc/cmdline
for word in "${cmdline_words[@]}"; do
  [[ "$word" == cosmarchy.snapshot=* ]] && SNAPSHOT_BOOTED="${word#*=}"
done
[[ -n "$SNAPSHOT_BOOTED" ]] && MODE=snapshot
REPORT_DIR="$HOME/.local/state/cosmarchy/verify"
mkdir -p "$REPORT_DIR"
exec >"$REPORT_DIR/$MODE.txt" 2>&1

pass=0
fail=0
ok() {
  echo "PASS  $1"
  trace "PASS $1"
  pass=$((pass + 1))
}
no() {
  echo "FAIL  $1${2:+ -- $2}"
  trace "FAIL $1 ${2:-}"
  fail=$((fail + 1))
}

finish() {
  echo
  echo "=== $pass passed, $fail failed ==="
  echo "RESULT: $([[ $fail -eq 0 ]] && echo SUCCESS || echo FAILURE)"
  sync
  trace "verification finished ($MODE): $pass passed, $fail failed"
  # Powering off ends the CI run via the explicit NOPASSWD sudoers rule.
  sudo -n systemctl poweroff 2>/dev/null ||
    systemctl poweroff 2>/dev/null ||
    sudo -n reboot 2>/dev/null ||
    trace "could not power off"
  exit 0
}

# session_proc NAME — is NAME running in this user's session? Not `pgrep -x`:
# that matches /proc/PID/comm, which the kernel cuts to 15 characters, so
# cosmic-settings-daemon (22) shows up as "cosmic-settings" and never matches.
# Match the executable at the start of the full command line instead.
session_proc() {
  pgrep -u "$(id -u)" -f "^(/usr/bin/)?$1( |\$)" >/dev/null
}

# Give COSMIC core components time to settle after autostart fires.
trace "waiting for COSMIC session components"
for _ in $(seq 1 20); do
  if session_proc cosmic-comp &&
    session_proc cosmic-panel &&
    session_proc cosmic-settings-daemon; then
    break
  fi
  sleep 2
done

echo "=== COSMIC session verification ==="
echo "session type: ${XDG_SESSION_TYPE:-unknown}"
echo "desktop:      ${XDG_CURRENT_DESKTOP:-unknown}"
echo

# --- Third boot: running from a snapshot ------------------------------------
if [[ "$MODE" == snapshot ]]; then
  n="$SNAPSHOT_BOOTED"
  echo "booted from snapshot $n"
  if session_proc cosmic-comp; then
    ok "a COSMIC session came up from snapshot $n"
  else
    no "cosmic-comp is not running on snapshot $n"
  fi
  [[ "$(findmnt -no FSTYPE /)" == overlay ]] && ok "/ is an overlay" ||
    no "/ is not an overlay" "$(findmnt -no FSTYPE,SOURCE,OPTIONS /)"
  [[ " ${cmdline_words[*]} " == *" rootflags=subvol=@snapshots/$n/snapshot "* ]] &&
    ok "the root is snapshot $n" || no "the command line does not point at snapshot $n"
  if echo probe >/var/tmp/cosmarchy-overlay-probe; then
    ok "the root accepts writes (CI checks they never reach the snapshot)"
  else
    no "the snapshot root is not writable"
  fi
  notified=0
  for _ in $(seq 1 30); do
    if journalctl --user -t cosmarchy-snapshot-notify --no-pager | grep -q "booted from snapshot $n"; then
      notified=1
      break
    fi
    sleep 1
  done
  ((notified)) && ok "the snapshot notice ran" || no "the snapshot notice never ran"
  echo "--- failed units (diagnostic only) ---"
  systemctl --failed --no-legend --no-pager
  if guard_out="$(/usr/local/lib/cosmarchy/boot/cosmarchy-boot guard 2>&1)"; then
    no "cosmarchy-boot guard lets a snapshot boot through"
  elif [[ "$guard_out" == *"running snapshot $n"* ]]; then
    ok "cosmarchy-boot guard refuses a snapshot boot and names it"
  else
    no "cosmarchy-boot guard refused without naming snapshot $n" "$guard_out"
  fi
  menu_before="$(b2sum /boot/limine.conf)"
  pkg="$(find /var/cache/pacman/pkg -name 'file-[0-9]*.pkg.tar.zst' | sort | tail -n1)"
  if [[ -z "$pkg" ]]; then
    no "no cached package to try a transaction with"
  elif sudo -n pacman -U --noconfirm "$pkg"; then
    no "pacman ran a transaction on a snapshot boot"
  else
    ok "pacman refuses a transaction on a snapshot boot"
  fi
  [[ "$(b2sum /boot/limine.conf)" == "$menu_before" ]] &&
    ok "the refused transaction left the menu alone" || no "the refused transaction changed limine.conf"
  if cosmarchy snapshot restore "$n" --yes; then
    ok "cosmarchy snapshot restore $n succeeded"
  else
    no "cosmarchy snapshot restore $n failed"
  fi
  grep -qx 'default_entry: Cosmarchy/linux' /boot/limine.conf &&
    ok "the menu defaults to linux again" || no "the menu does not default to linux after the restore"
  finish
fi

# --- Core COSMIC session processes -----------------------------------------
for proc in cosmic-comp cosmic-panel cosmic-settings-daemon; do
  if session_proc "$proc"; then
    ok "$proc is running"
  else
    no "$proc is not running"
  fi
done

# --- Shortcut RON parse health in the journal ------------------------------
# cosmic-settings-daemon logs "shortcuts custom config error" or
# "failed to read local shortcuts config 'system_actions'" if any RON file fails
# to deserialize, or "Skipping over invalid Action"/"SystemAction" on bad entries.
journal_dump="$(journalctl --user -b --no-pager 2>/dev/null || true)"
sys_journal="$(journalctl -b --no-pager 2>/dev/null || true)"
all_journal="${journal_dump}"$'\n'"${sys_journal}"

shortcut_errors="$(grep -iE "shortcuts custom config error|shortcuts config 'system_actions'|Skipping over invalid Action|Skipping over invalid SystemAction" <<<"$all_journal" || true)"
if [[ -z "$shortcut_errors" ]]; then
  ok "no shortcut custom/system_actions config errors in journal"
else
  no "COSMIC shortcut RON errors logged" "$(head -n 5 <<<"$shortcut_errors")"
fi

# --- Every Cosmarchy shortcut key must be absent from COSMIC defaults ------
DEFAULTS_RON="/usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults"
CUSTOM_RON="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"

if [[ -r "$DEFAULTS_RON" && -r "$CUSTOM_RON" ]]; then
  collision_report="$(python3 - "$DEFAULTS_RON" "$CUSTOM_RON" <<'PY'
import re, sys

def parse(path):
    text = open(path, encoding="utf-8").read()
    bindings = {}
    pat = re.compile(
        r'\(modifiers:\s*\[([^\]]*)\](?:,\s*key:\s*"([^"]+)")?(?:,\s*keycode:\s*\d+)?(?:,\s*description:\s*Some\("[^"]*"\))?\)\s*:\s*([^,\n]+)'
    )
    for m in pat.finditer(text):
        mods = tuple(sorted(x.strip() for x in m.group(1).split(",") if x.strip()))
        key = (m.group(2) or "").lower()
        bindings[(mods, key)] = m.group(3).strip()
    return bindings

defaults = parse(sys.argv[1])
custom = parse(sys.argv[2])
if not defaults:
    print("ERROR: parsed 0 default bindings")
    sys.exit(2)
if not custom:
    print("ERROR: parsed 0 custom bindings")
    sys.exit(2)

clashes = []
for k, act in custom.items():
    if k in defaults:
        clashes.append(f"{'+'.join(k[0])}+{k[1]} (custom={act} vs default={defaults[k]})")

if clashes:
    print("CLASH: " + "; ".join(clashes))
    sys.exit(1)
print(f"OK: {len(custom)} custom bindings verified free against {len(defaults)} COSMIC defaults")
PY
)"
  rc=$?
  if ((rc == 0)); then
    ok "$collision_report"
  else
    no "Cosmarchy shortcut overlaps COSMIC defaults" "$collision_report"
  fi
else
  no "shortcut RON files unreadable" "defaults=$DEFAULTS_RON custom=$CUSTOM_RON"
fi

# --- pop-launcher discovers the Cosmarchy plugin ---------------------------
if command -v pop-launcher >/dev/null 2>&1; then
  if launcher_report="$(python3 - <<'PY'
import select, subprocess, sys, time

proc = subprocess.Popen(
    ["pop-launcher"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    encoding="utf-8",
    bufsize=1,
)

# Keep stdin open until pop-launcher answers: its service loop runs
# futures::future::select(request_handler, response_handler) and exits
# immediately on stdin EOF before plugins can reply.
proc.stdin.write('{"Search":"c snap"}\n')
proc.stdin.flush()

seen = []
found = False
deadline = time.monotonic() + 10.0
while time.monotonic() < deadline:
    remaining = max(0.0, deadline - time.monotonic())
    ready, _, _ = select.select([proc.stdout], [], [], remaining)
    if not ready:
        break
    line = proc.stdout.readline()
    if not line:
        break
    seen.append(line.strip())
    if "Create snapshot" in line:
        found = True
        break

try:
    proc.stdin.write('"Exit"\n')
    proc.stdin.flush()
    proc.stdin.close()
except OSError:
    pass
try:
    proc.wait(timeout=3)
except subprocess.TimeoutExpired:
    proc.terminate()
    proc.wait(timeout=2)

if found:
    print("OK: pop-launcher returned Create snapshot for c snap")
    sys.exit(0)
stderr = proc.stderr.read().strip()
print(f"MISSING: seen={seen!r} stderr={stderr!r}")
sys.exit(1)
PY
)"; then
    ok "$launcher_report"
  else
    no "pop-launcher did not return Create snapshot for 'c snap'" "$launcher_report"
  fi
else
  no "pop-launcher binary not found in PATH"
fi

# --- Tiling & keyboard config ----------------------------------------------
COMP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicComp/v1"
if [[ -r "$COMP_DIR/autotile" ]] && [[ "$(tr -d '[:space:]' < "$COMP_DIR/autotile")" == "true" ]]; then
  ok "COSMIC autotile is true"
else
  no "COSMIC autotile is not true" "got: $(cat "$COMP_DIR/autotile" 2>/dev/null || echo missing)"
fi

if [[ -r "$COMP_DIR/autotile_behavior" ]] && [[ "$(tr -d '[:space:]' < "$COMP_DIR/autotile_behavior")" == "PerWorkspace" ]]; then
  ok "COSMIC autotile_behavior is PerWorkspace"
else
  no "COSMIC autotile_behavior is not PerWorkspace" "got: $(cat "$COMP_DIR/autotile_behavior" 2>/dev/null || echo missing)"
fi

if [[ -f /etc/cosmarchy/keyboard.conf ]]; then
  kb_layout="$(sed -n 's/^XKB_LAYOUT=//p' /etc/cosmarchy/keyboard.conf)"
  kb_latin="$(sed -n 's/^LATIN=//p' /etc/cosmarchy/keyboard.conf)"
  expected_layout="$kb_layout"
  [[ "$kb_latin" == no ]] && expected_layout="us,$kb_layout"
  if [[ -r "$COMP_DIR/xkb_config" ]] && grep -qF "layout: \"$expected_layout\"" "$COMP_DIR/xkb_config"; then
    ok "COSMIC xkb_config layout matches installer ($expected_layout)"
  else
    no "COSMIC xkb_config layout does not match $expected_layout" "$(cat "$COMP_DIR/xkb_config" 2>/dev/null || echo missing)"
  fi
fi

# --- XDG Desktop Portal (COSMIC) answers on the session D-Bus --------------
portal_ok=0
for _ in $(seq 1 10); do
  if busctl --user call org.freedesktop.impl.portal.desktop.cosmic \
    /org/freedesktop/portal/desktop org.freedesktop.DBus.Peer Ping >/dev/null 2>&1; then
    portal_ok=1
    break
  fi
  sleep 1
done
if ((portal_ok)); then
  ok "xdg-desktop-portal-cosmic answers on the session D-Bus"
else
  no "xdg-desktop-portal-cosmic did not answer on the session D-Bus"
fi

# --- Timezone --------------------------------------------------------------
tz="$(timedatectl show -p Timezone --value)"
[[ "$tz" == Europe/Berlin ]] && ok "the timezone is Europe/Berlin" || no "the timezone is $tz"

# --- Boot menu: snapshots, snap-pac and fixed COSMIC Dark palette ----------
BOOT_BIN=/usr/local/lib/cosmarchy/boot/cosmarchy-boot
LIMINE=/boot/limine.conf

limine_refs_ok() {
  local path hash bad=0
  while read -r path hash; do
    if [[ ! -f "/boot$path" || "$(b2sum "/boot$path" | cut -d' ' -f1)" != "$hash" ]]; then
      echo "      bad reference: $path"
      bad=1
    fi
  done < <(sed -nE 's/^[[:space:]]*(kernel_path|module_path): boot\(\):([^#]+)#([0-9a-f]+)$/\2 \3/p' "$LIMINE")
  return "$bad"
}

snap="$(sudo -n snapper -c root create --print-number --description 'CI session snapshot')"
if [[ "$snap" =~ ^[0-9]+$ ]] && grep -q "^///$snap | " "$LIMINE"; then
  ok "snapshot $snap, made through snapperd, is in the boot menu"
else
  no "a snapshot made through snapperd did not reach the boot menu" "snapper printed: $snap"
fi
limine_refs_ok && ok "every boot file in limine.conf matches its hash" || no "limine.conf has stale references"

pkg="$(find /var/cache/pacman/pkg -name 'file-[0-9]*.pkg.tar.zst' | sort | tail -n1)"
if [[ -n "$pkg" ]] && sudo -n pacman -U --noconfirm "$pkg"; then
  post="$(sudo -n snapper --csvout --no-headers -c root list --columns number,type |
    awk -F, '$2 == "post" { n = $1 } END { print n }')"
  if [[ -n "$post" ]] && ((post > snap)) && grep -q "^///$post | " "$LIMINE"; then
    ok "snap-pac's post snapshot $post of a pacman transaction is in the boot menu"
  else
    no "no post snapshot of the pacman transaction in the boot menu" "newest post: ${post:-none}"
  fi
else
  no "could not reinstall the file package from the cache" "${pkg:-no package found}"
fi

grep -qx "term_background: 001b1b1b" "$LIMINE" &&
  ok "limine.conf carries the fixed COSMIC Dark palette" ||
  no "limine.conf does not carry the COSMIC Dark palette" "$(grep '^term_background' "$LIMINE")"

# --- Windows apps: WinBoat is opt-in, its prerequisites are not -------------
if windows_status="$(cosmarchy windows status 2>&1)"; then
  ok "cosmarchy windows status runs"
else
  no "cosmarchy windows status failed" "$windows_status"
fi
[[ "$windows_status" == *"not installed (cosmarchy windows install)"* ]] &&
  ok "WinBoat is not installed until asked for" || no "WinBoat status is unexpected" "$windows_status"
[[ "$windows_status" == *"Docker: the service is running"* ]] &&
  ok "Docker is running for WinBoat" || no "Docker is not running" "$windows_status"
[[ "$windows_status" == *"is in the docker group"* ]] &&
  ok "the user is in the docker group in the session" || no "the session lacks the docker group" "$windows_status"

# Hand over to the third boot: the snapshot made above, which, unlike
# snapshot 1, includes CI's autologin and this script.
if [[ "$snap" =~ ^[0-9]+$ ]] && sudo -n "$BOOT_BIN" update --default "snapshot:$snap" &&
  grep -q "^default_entry: Cosmarchy/Snapshots/$snap | " "$LIMINE"; then
  ok "the next boot defaults to snapshot $snap"
  echo "SNAPSHOT: $snap"
else
  no "could not make snapshot $snap the next boot's default"
fi

finish
