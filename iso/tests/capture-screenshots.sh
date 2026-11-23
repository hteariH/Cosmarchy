#!/bin/bash

# In-guest half of the screenshot capture: compose the COSMIC desktop, hold each
# arrangement still, and record in the transcript when each stage was on screen.
#
# Pictures are captured from outside by QEMU dumping the video framebuffer on a
# timer while this script drives the desktop. See iso/tests/capture-host.sh.

REPORT="/var/tmp/cosmarchy-capture.txt"
STATE_DIR="$HOME/.local/state/cosmarchy"
PHASE_FILE="$STATE_DIR/capture-phase"

HOLD="${COSMARCHY_CAPTURE_HOLD:-12}"

mkdir -p "$STATE_DIR"

trace() {
  # logger may not exist in minimal environments; trace is best-effort.
  logger -t cosmarchy-capture -- "$*" 2>/dev/null || true
}

exec >>"$REPORT" 2>&1

phase="$(cat "$PHASE_FILE" 2>/dev/null || echo 1)"
trace "capture started, phase=$phase, session=${XDG_SESSION_TYPE:-unknown}"

echo "=== capture phase $phase ==="
echo "date: $(date -Is)"
echo "session type: ${XDG_SESSION_TYPE:-unknown}"
echo "user: $(whoami)"
echo "hold per stage: ${HOLD}s"
echo

if ((phase > 1)); then
  echo "phase $phase is past the end - powering off"
  sudo -n systemctl poweroff 2>/dev/null || systemctl poweroff 2>/dev/null
  exit 0
fi

power_off() {
  echo
  echo "powering off at $(date -Is)"
  sync
  sudo -n systemctl poweroff 2>/dev/null || systemctl poweroff 2>/dev/null
}

stage() {
  local name="$1"
  echo "STAGE $name  start=$(date -Is)"
  sleep "$HOLD"
  echo "STAGE $name  end=$(date -Is)"
  trace "stage $name held ${HOLD}s"
}

launched_pids=()
launch() {
  setsid "$@" >/dev/null 2>&1 &
  launched_pids+=("$!")
  trace "launched: $*"
  sleep 6
}

close_launched() {
  local pid
  for pid in "${launched_pids[@]}"; do
    kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  done
  launched_pids=()
  sleep 4
}

if [[ "$phase" == "1" ]]; then
  echo "--- waiting for COSMIC session ---"
  for _ in $(seq 1 20); do
    if pgrep -u "$(id -u)" -x cosmic-comp >/dev/null &&
      pgrep -u "$(id -u)" -x cosmic-panel >/dev/null; then
      break
    fi
    sleep 2
  done

  sleep 15

  echo "--- stages ---"
  stage 01-desktop

  launch cosmic-term --no-daemon -e cosmarchy-menu
  stage 02-menu
  close_launched

  launch cosmic-term --no-daemon -e cosmarchy-keybindings
  stage 03-keybindings
  close_launched

  launch cosmic-term --no-daemon -e cosmarchy-manual
  stage 04-manual
  close_launched

  launch cosmic-term --no-daemon -e btop
  stage 05-terminal-btop

  launch cosmic-term --no-daemon -e nvim "$HOME/.local/share/cosmarchy/README.md"
  stage 06-neovim
  close_launched

  launch cosmic-files
  stage 07-files
  close_launched

  echo 2 > "$PHASE_FILE"

  echo
  echo "phase 1 complete"
  trace "phase 1 complete"
  power_off
  exit 0
fi
