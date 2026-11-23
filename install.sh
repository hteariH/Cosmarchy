#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Cosmarchy locations
export COSMARCHY_PATH="${COSMARCHY_PATH:-$HOME/.local/share/cosmarchy}"
export COSMARCHY_INSTALL="$COSMARCHY_PATH/install"
export COSMARCHY_INSTALL_LOG_FILE="/var/log/cosmarchy-install.log"
export PATH="$COSMARCHY_PATH/bin:$HOME/.local/bin:$PATH"

# Ensure all Cosmarchy scripts are executable
chmod +x "$COSMARCHY_PATH/bin"/* 2>/dev/null || true

# Symlink cosmarchy CLI globally to /usr/local/bin for all users
sudo ln -sf "$COSMARCHY_PATH/bin/cosmarchy" /usr/local/bin/cosmarchy 2>/dev/null || true
sudo chmod +x /usr/local/bin/cosmarchy 2>/dev/null || true

# Mirror everything into the install log.
#
# This block previously created only the log's directory and never wrote to it,
# so the file the error handler points at ("Review detailed log output in ...")
# was always empty and no installation failure could be diagnosed after the
# fact.
sudo mkdir -p "$(dirname "$COSMARCHY_INSTALL_LOG_FILE")" 2>/dev/null || true
sudo touch "$COSMARCHY_INSTALL_LOG_FILE" 2>/dev/null || true
sudo chmod 666 "$COSMARCHY_INSTALL_LOG_FILE" 2>/dev/null || true

if [[ -w "$COSMARCHY_INSTALL_LOG_FILE" ]]; then
  exec > >(tee -a "$COSMARCHY_INSTALL_LOG_FILE") 2>&1
  echo "===== Cosmarchy install started $(date -Iseconds) ====="
  echo "===== chroot=${COSMARCHY_CHROOT_INSTALL:-0} user=${USER:-?} path=$COSMARCHY_PATH ====="
fi

# Run each stage with a marker either side, so a log always shows which stage
# failed rather than just ending.
export COSMARCHY_STAGE=""
run_stage() {
  export COSMARCHY_STAGE="$1"
  echo "===== STAGE START: $1 ====="
  source "$COSMARCHY_INSTALL/$1/all.sh"
  echo "===== STAGE OK: $1 ====="
}

source "$COSMARCHY_INSTALL/helpers/all.sh"

run_stage preflight
run_stage packaging
run_stage config
run_stage desktop
run_stage login
run_stage post-install

echo "===== Cosmarchy install finished $(date -Iseconds) ====="
