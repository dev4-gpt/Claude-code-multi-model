#!/usr/bin/env bash
# Non-interactive smoke test: Claude Code + Ollama (Anthropic-compatible env).
# Requires: `ollama serve` running, model pulled (default: qwen3.5:4b).
#
# Usage:
#   ./scripts/verify-ollama-claude.sh
#   ANTHROPIC_BASE_URL=http://127.0.0.1:11434 MODEL=qwen3.5:4b ./scripts/verify-ollama-claude.sh

set -euo pipefail

MODEL="${MODEL:-qwen3.5:4b}"
ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-http://127.0.0.1:11434}"

export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_API_KEY=ollama
export ANTHROPIC_BASE_URL

echo "Testing: claude -p (print) via Ollama at ${ANTHROPIC_BASE_URL}, model=${MODEL}"
if ! command -v claude >/dev/null 2>&1; then
  echo "error: claude not found in PATH" >&2
  exit 1
fi

out="$(claude --model "$MODEL" -p "Reply with exactly: OK" </dev/null 2>&1)" || {
  echo "$out" >&2
  exit 1
}
echo "$out"
if echo "$out" | grep -q "Not logged in"; then
  echo "FAIL: still seeing Not logged in — check ANTHROPIC_* dummy token+key and Ollama URL." >&2
  exit 1
fi
echo "OK — Claude Code reached Ollama (no Not logged in)."
