#!/bin/bash
# Tests the Cosmarchy pop-launcher plugin, action catalog, install stage,
# flat cosmarchy-menu catalog listing, and v0.1.0 migration.
set -u
cd "$(dirname "$0")/../.." || exit 1
# shellcheck source=iso/tests/lib/assert.sh
source iso/tests/lib/assert.sh

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s' "$1"
  fi
}

is_windows_shell() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

# Create a POSIX stub executable plus a Windows .cmd shim under Git Bash so
# Windows Python's subprocess can execute extensionless stubs via PATH.
make_stub() {
  local dir="$1" name="$2" body="$3"
  printf '#!/bin/bash\n%s\n' "$body" >"$dir/$name"
  chmod +x "$dir/$name"
  if is_windows_shell; then
    local win_bash
    win_bash="$(cygpath -w "$(command -v bash)")"
    printf '@"%s" "%%~dp0%s" %%*\r\n' "$win_bash" "$name" >"$dir/$name.cmd"
  fi
}

echo "--- plugin syntax & plugin.ron"
t_true "cosmarchy-launcher compiles with py_compile" python3 -m py_compile launcher/cosmarchy/cosmarchy-launcher
t_true "plugin.ron exists" test -f launcher/cosmarchy/plugin.ron
t_true "plugin.ron matches ^c  prefix" grep -qF 'regex: "^c ",' launcher/cosmarchy/plugin.ron
t_true "plugin.ron sets isolate: true" grep -qF 'isolate: true,' launcher/cosmarchy/plugin.ron
t_true "plugin.ron sets help: \"c \"" grep -qF 'help: "c ",' launcher/cosmarchy/plugin.ron
t_true "plugin.ron names cosmarchy-launcher binary" grep -qF 'bin: (path: "cosmarchy-launcher"),' launcher/cosmarchy/plugin.ron

echo "--- actions.tsv validation"
CATALOG_CHECK="$(python3 - "$(native_path "$PWD")" <<'PY'
import pathlib, shlex, sys

root = pathlib.Path(sys.argv[1])
tsv = root / "launcher" / "actions.tsv"
lines = tsv.read_text(encoding="utf-8").splitlines()
if not lines:
    sys.exit("actions.tsv is empty")
if lines[0] != "id\ttitle\tkeywords\tmode\tcommand":
    sys.exit(f"unexpected header: {lines[0]!r}")

seen = set()
valid_modes = {"run", "notify", "terminal"}
found_create_snap = False
for lineno, line in enumerate(lines[1:], start=2):
    fields = line.split("\t")
    if len(fields) != 5:
        sys.exit(f"line {lineno}: expected 5 fields, got {len(fields)}")
    aid, title, keywords, mode, cmd = fields
    if not all(f.strip() for f in fields):
        sys.exit(f"line {lineno}: empty field in {fields!r}")
    if aid in seen:
        sys.exit(f"line {lineno}: duplicate id {aid!r}")
    seen.add(aid)
    if mode not in valid_modes:
        sys.exit(f"line {lineno}: invalid mode {mode!r}")
    argv = shlex.split(cmd)
    exe = root / "bin" / argv[0]
    if not exe.is_file():
        sys.exit(f"line {lineno}: executable {argv[0]!r} missing from bin/")
    if title == "Create snapshot":
        found_create_snap = True

if not found_create_snap:
    sys.exit("actions.tsv does not contain 'Create snapshot'")
print(f"OK: {len(seen)} actions validated")
PY
)"
rc=$?
t_eq "actions.tsv has 5 fields, valid modes, and executables in bin/" "$rc" "0"
[[ $rc -ne 0 ]] && echo "        $CATALOG_CHECK"

echo "--- cosmarchy-menu --list reads actions.tsv"
menu_rc=0
MENU_OUT="$(COSMARCHY_PATH="$PWD" bash bin/cosmarchy-menu --list 2>&1)" || menu_rc=$?
t_eq "cosmarchy-menu --list exits 0" "$menu_rc" "0"
t_true "cosmarchy-menu --list includes Create snapshot" grep -qF "Create snapshot" <<<"$MENU_OUT"

echo "--- plugin IPC (Search, Activate, keybindings, manual, notify)"
FAKE_ROOT="$T/fake-cosmarchy"
STUB_BIN="$T/stubs"
MARKER_DIR="$T/markers"
mkdir -p "$FAKE_ROOT/launcher" "$STUB_BIN" "$MARKER_DIR"
cp launcher/actions.tsv "$FAKE_ROOT/launcher/actions.tsv"

MARKER_DIR_POSIX="$MARKER_DIR"
make_stub "$STUB_BIN" cosmarchy-keybindings '
if [[ "${1:-}" == "--list" ]]; then
  printf "Cosmarchy Keybindings (COSMIC)\n\n"
  printf "Cosmarchy & Custom Shortcuts\n"
  printf "%-28s  %s\n" "Ctrl + Print" "Annotate Screenshot"
  printf "%-28s  %s\n" "Super + Alt + Space" "Cosmarchy Menu"
  printf "\nCOSMIC Defaults\n"
  printf "%-28s  %s\n" "Super + Y" "Toggle Tiling"
  printf "\nConfigure shortcuts in COSMIC Settings -> Input Devices -> Keyboard -> Shortcuts.\n"
fi
'
make_stub "$STUB_BIN" cosmarchy-manual '
if [[ "${1:-}" == "--list" ]]; then
  printf "04  Tiling\n"
  printf "14  Snapshots\n"
fi
'
make_stub "$STUB_BIN" cosmarchy-tiling "
if [[ \"\${1:-}\" == \"status\" ]]; then
  printf '\033[1;32mTiling: on\033[0m (COSMIC autotile)\n'
else
  printf '%s\n' \"\$*\" >\"$MARKER_DIR_POSIX/tiling.marker\"
fi
"
make_stub "$STUB_BIN" cosmic-term "
printf '%s\n' \"\$*\" >\"$MARKER_DIR_POSIX/term.marker\"
"
make_stub "$STUB_BIN" notify-send "
printf '%s\n' \"\$*\" >\"$MARKER_DIR_POSIX/notify.marker\"
"

IPC_REPORT="$(
  COSMARCHY_PATH="$(native_path "$FAKE_ROOT")" \
  PATH="$STUB_BIN:$PATH" \
  python3 - "$(native_path "$PWD/launcher/cosmarchy/cosmarchy-launcher")" "$(native_path "$MARKER_DIR")" <<'PY'
import json, os, pathlib, subprocess, sys, time

plugin = sys.argv[1]
markers = pathlib.Path(sys.argv[2])
cmd = [plugin] if os.name == "posix" else [sys.executable, plugin]

proc = subprocess.Popen(
    cmd,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    encoding="utf-8",
    bufsize=1,
)

def send(obj):
    proc.stdin.write(json.dumps(obj) + "\n")
    proc.stdin.flush()

def read_until(sentinel):
    lines = []
    while True:
        raw = proc.stdout.readline()
        if not raw:
            raise AssertionError(f"EOF before {sentinel!r}; got {lines!r}")
        item = json.loads(raw)
        lines.append(item)
        if item == sentinel:
            return lines

def wait_file(path, timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if path.exists() and path.read_text(encoding="utf-8").strip():
            return path.read_text(encoding="utf-8").strip()
        time.sleep(0.05)
    return None

# 1. c snap -> Create snapshot
send({"Search": "c snap"})
resp = read_until("Finished")
appends = [r["Append"] for r in resp[:-1]]
assert appends and appends[0]["name"] == "Create snapshot", f"unexpected c snap: {resp}"
for a in appends:
    assert set(a.keys()) >= {"id", "name", "description", "keywords", "icon", "exec", "window"}
    if a["icon"] is not None:
        assert "Name" in a["icon"] or "Mime" in a["icon"]

# 2. c  alone -> actions, at most 8
send({"Search": "c "})
resp = read_until("Finished")
appends = [r["Append"] for r in resp[:-1]]
assert 1 <= len(appends) <= 8, f"expected 1..8 actions, got {len(appends)}"

# 3. c key screen -> Ctrl + Print — Annotate Screenshot; activate closes only
send({"Search": "c key screen"})
resp = read_until("Finished")
appends = [r["Append"] for r in resp[:-1]]
assert any("Ctrl + Print" in a["name"] and "Annotate Screenshot" in a["name"] for a in appends), f"unexpected c key: {resp}"
send({"Activate": 0})
assert read_until("Close") == ["Close"]
time.sleep(0.15)
assert not (markers / "term.marker").exists(), "keybinding activation should not spawn cosmic-term"

# 4. c man snap -> 14 · Snapshots; activate spawns cosmic-term -e cosmarchy-manual 14
send({"Search": "c man snap"})
resp = read_until("Finished")
appends = [r["Append"] for r in resp[:-1]]
assert any("14 · Snapshots" in a["name"] for a in appends), f"unexpected c man: {resp}"
send({"Activate": 0})
assert read_until("Close") == ["Close"]
term_args = wait_file(markers / "term.marker")
assert term_args == "-e cosmarchy-manual 14", f"unexpected cosmic-term args: {term_args!r}"

# 5. Activate run action -> executes command and writes marker
send({"Search": "c toggle auto-tiling"})
resp = read_until("Finished")
appends = [r["Append"] for r in resp[:-1]]
assert appends and appends[0]["name"] == "Toggle auto-tiling", f"unexpected c toggle: {resp}"
send({"Activate": 0})
assert read_until("Close") == ["Close"]
tiling_args = wait_file(markers / "tiling.marker")
assert tiling_args == "toggle", f"unexpected tiling marker: {tiling_args!r}"

# 6. Activate notify action -> runs command, strips ANSI, invokes notify-send
send({"Search": "c tiling status"})
resp = read_until("Finished")
appends = [r["Append"] for r in resp[:-1]]
assert appends and appends[0]["name"] == "Tiling status", f"unexpected c tiling status: {resp}"
send({"Activate": 0})
assert read_until("Close") == ["Close"]
notify_args = wait_file(markers / "notify.marker")
assert notify_args is not None and "Tiling status" in notify_args and "Tiling: on (COSMIC autotile)" in notify_args, f"unexpected notify: {notify_args!r}"
assert "\x1b[" not in notify_args, f"ANSI escape leaked into notify-send: {notify_args!r}"

# 7. Clean exit
send("Exit")
proc.stdin.close()
rc = proc.wait(timeout=5)
stderr = proc.stderr.read()
assert rc == 0, f"plugin exited with {rc}, stderr={stderr!r}"
print("OK")
PY
)"
t_eq "plugin IPC search, keybindings, manual, run, notify, and exit" "$IPC_REPORT" "OK"

echo "--- broken source yields error item + stderr + Finished"
BROKEN_ROOT="$T/broken-cosmarchy"
BROKEN_STUBS="$T/broken-stubs"
mkdir -p "$BROKEN_ROOT" "$BROKEN_STUBS"
make_stub "$BROKEN_STUBS" cosmarchy-keybindings 'echo "ron broken" >&2; exit 1'
make_stub "$BROKEN_STUBS" cosmarchy-manual 'echo "manual dir missing" >&2; exit 1'

BROKEN_REPORT="$(
  COSMARCHY_PATH="$(native_path "$BROKEN_ROOT")" \
  PATH="$BROKEN_STUBS:$PATH" \
  python3 - "$(native_path "$PWD/launcher/cosmarchy/cosmarchy-launcher")" <<'PY'
import json, os, subprocess, sys

plugin = sys.argv[1]
cmd = [plugin] if os.name == "posix" else [sys.executable, plugin]
proc = subprocess.Popen(
    cmd,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    encoding="utf-8",
    bufsize=1,
)

for query, expected_prefix in [
    ("c snap", "Cosmarchy: actions unavailable — "),
    ("c key screen", "Cosmarchy: keybindings unavailable — "),
    ("c man snap", "Cosmarchy: manual unavailable — "),
]:
    proc.stdin.write(json.dumps({"Search": query}) + "\n")
    proc.stdin.flush()
    lines = []
    while True:
        raw = proc.stdout.readline()
        assert raw, f"EOF during broken-source search {query!r}"
        obj = json.loads(raw)
        lines.append(obj)
        if obj == "Finished":
            break
    assert len(lines) == 2, f"expected 1 error result + Finished for {query!r}, got {lines!r}"
    name = lines[0]["Append"]["name"]
    assert name.startswith(expected_prefix), f"unexpected error item {name!r}"

proc.stdin.write('"Exit"\n')
proc.stdin.flush()
proc.stdin.close()
rc = proc.wait(timeout=5)
stderr = proc.stderr.read()
assert rc == 0, f"plugin exited {rc}"
assert "actions unavailable:" in stderr and "keybindings unavailable:" in stderr and "manual unavailable:" in stderr, f"stderr missing reasons: {stderr!r}"
print("OK")
PY
)"
t_eq "broken sources return error items, log to stderr, and finish cleanly" "$BROKEN_REPORT" "OK"

echo "--- install/config/launcher.sh"
INSTALL_HOME="$T/install-home"
mkdir -p "$INSTALL_HOME"
t_true "install/config/launcher.sh succeeds" env HOME="$INSTALL_HOME" XDG_DATA_HOME="$INSTALL_HOME/.local/share" COSMARCHY_PATH="$PWD" bash install/config/launcher.sh
INSTALL_LINK="$INSTALL_HOME/.local/share/pop-launcher/plugins/cosmarchy"
if is_windows_shell; then
  t_true "plugin path deployed under pop-launcher/plugins/cosmarchy" test -e "$INSTALL_LINK/plugin.ron"
else
  t_true "plugin link is a symlink" test -L "$INSTALL_LINK"
  t_eq "plugin symlink target" "$(readlink "$INSTALL_LINK")" "$PWD/launcher/cosmarchy"
fi

echo "--- v0.1.0 migration (rewrite, idempotency, user-rebound preservation)"
MIG_SCRIPT="migrations/2026-11-23-1200-launcher-plugin.sh"
t_true "migration script exists" test -f "$MIG_SCRIPT"

MIG_HOME="$T/mig-v010"
CUSTOM_DIR="$MIG_HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
mkdir -p "$CUSTOM_DIR"
cat >"$CUSTOM_DIR/custom" <<'EOF'
{
    (modifiers: [Super], key: "Return", description: Some("Terminal")): Spawn("cosmic-term"),
    (modifiers: [Super], key: "e", description: Some("Files")): Spawn("cosmic-files"),
    (modifiers: [Super], key: "d", description: Some("Voxtype AI Dictation")): Spawn("cosmarchy voxtype toggle"),
    (modifiers: [Ctrl], key: "Print", description: Some("Annotate Screenshot")): Spawn("cosmarchy-capture annotate"),
    (modifiers: [Super, Alt], key: "space", description: Some("Cosmarchy Menu")): Spawn("cosmic-term -e cosmarchy-menu"),
    (modifiers: [Super, Alt], key: "slash", description: Some("Cosmarchy Keybindings")): Spawn("cosmic-term -e cosmarchy-keybindings"),
    (modifiers: [Super, Alt], key: "m", description: Some("Cosmarchy Manual")): Spawn("cosmic-term -e cosmarchy-manual"),
}
EOF

t_true "migration runs cleanly on v0.1.0 custom file" env HOME="$MIG_HOME" XDG_CONFIG_HOME="$MIG_HOME/.config" XDG_DATA_HOME="$MIG_HOME/.local/share" COSMARCHY_PATH="$PWD" bash "$MIG_SCRIPT"
t_true "migrated custom matches shipped default/cosmic/.../custom" cmp -s "default/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" "$CUSTOM_DIR/custom"
MIG_LINK="$MIG_HOME/.local/share/pop-launcher/plugins/cosmarchy"
if is_windows_shell; then
  t_true "migration deploys plugin under pop-launcher/plugins/cosmarchy" test -e "$MIG_LINK/plugin.ron"
else
  t_true "migration creates plugin symlink" test -L "$MIG_LINK"
  t_eq "migration plugin symlink target" "$(readlink "$MIG_LINK")" "$PWD/launcher/cosmarchy"
fi

cp "$CUSTOM_DIR/custom" "$T/custom.after-first"
t_true "migration second run succeeds (no-op)" env HOME="$MIG_HOME" XDG_CONFIG_HOME="$MIG_HOME/.config" XDG_DATA_HOME="$MIG_HOME/.local/share" COSMARCHY_PATH="$PWD" bash "$MIG_SCRIPT"
t_true "second run leaves custom byte-identical" cmp -s "$T/custom.after-first" "$CUSTOM_DIR/custom"

REBOUND_HOME="$T/mig-rebound"
REBOUND_DIR="$REBOUND_HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
mkdir -p "$REBOUND_DIR"
cat >"$REBOUND_DIR/custom" <<'EOF'
{
    (modifiers: [Super], key: "Return", description: Some("Terminal")): Spawn("cosmic-term"),
    (modifiers: [Super, Alt], key: "space", description: Some("Cosmarchy Menu")): Spawn("my-custom-menu"),
    (modifiers: [Super, Alt], key: "slash", description: Some("Cosmarchy Keybindings")): Spawn("cosmic-term -e cosmarchy-keybindings"),
    (modifiers: [Super, Alt], key: "m", description: Some("Cosmarchy Manual")): Spawn("cosmic-term -e cosmarchy-manual"),
}
EOF

t_true "migration runs on user-rebound custom file" env HOME="$REBOUND_HOME" XDG_CONFIG_HOME="$REBOUND_HOME/.config" XDG_DATA_HOME="$REBOUND_HOME/.local/share" COSMARCHY_PATH="$PWD" bash "$MIG_SCRIPT"
t_true "user-rebound Super+Alt+Space line left untouched" grep -qF 'Spawn("my-custom-menu")' "$REBOUND_DIR/custom"
t_true "unmodified Super+Alt+/ line rewritten" grep -qF 'Spawn("cosmic-launcher input \"c key \"")' "$REBOUND_DIR/custom"
t_true "unmodified Super+Alt+M line rewritten" grep -qF 'Spawn("cosmic-launcher input \"c man \"")' "$REBOUND_DIR/custom"

EMPTY_HOME="$T/mig-empty"
mkdir -p "$EMPTY_HOME"
t_true "migration succeeds when custom file is absent" env HOME="$EMPTY_HOME" XDG_CONFIG_HOME="$EMPTY_HOME/.config" XDG_DATA_HOME="$EMPTY_HOME/.local/share" COSMARCHY_PATH="$PWD" bash "$MIG_SCRIPT"
t_true "migration still deploys plugin when custom file is absent" test -e "$EMPTY_HOME/.local/share/pop-launcher/plugins/cosmarchy/plugin.ron"

t_done
