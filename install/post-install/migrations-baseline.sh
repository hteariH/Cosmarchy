#!/bin/bash

cosmarchy_header "Baselining Migration Ledger"

# A fresh install already produces the end state that every existing migration
# describes, so record them as applied rather than replaying them.
if command -v cosmarchy-migrate >/dev/null 2>&1; then
  cosmarchy-migrate --baseline || true
elif [[ -x "$COSMARCHY_PATH/bin/cosmarchy-migrate" ]]; then
  "$COSMARCHY_PATH/bin/cosmarchy-migrate" --baseline || true
fi

cosmarchy_step "Migration ledger baselined"
