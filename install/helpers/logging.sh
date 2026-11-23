#!/bin/bash

# Ensure log destination is writable
if sudo -n true 2>/dev/null; then
  sudo touch "$COSMARCHY_INSTALL_LOG_FILE" 2>/dev/null || true
  sudo chmod 666 "$COSMARCHY_INSTALL_LOG_FILE" 2>/dev/null || true
fi

log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$COSMARCHY_INSTALL_LOG_FILE" 2>/dev/null || true
}
