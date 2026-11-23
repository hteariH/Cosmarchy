#!/bin/bash

cosmarchy_header "Deploying Cosmarchy AI Agent Skills"

SKILL_SOURCE="$COSMARCHY_PATH/default/cosmarchy-skill"

if [ -d "$SKILL_SOURCE" ]; then
  # Deploy to standard AI coding agent skill directories
  AGENT_DIRS=(
    "$HOME/.agents/skills"
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.pi/agent/skills"
    "$HOME/.gemini/antigravity/skills"
    "$HOME/.config/opencode/skills"
  )

  for dir in "${AGENT_DIRS[@]}"; do
    mkdir -p "$dir"
    ln -sfn "$SKILL_SOURCE" "$dir/cosmarchy" 2>/dev/null || true
  done

  cosmarchy_step "Cosmarchy skill deployed to Claude Code, Codex, Pi, and open agent registries"
fi
