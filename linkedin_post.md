# Built a Multi-Provider Claude Code Router (NVIDIA + OpenRouter + Ollama)

I just finished a practical Claude Code setup on macOS that solves two real pain points:

1. Provider lock-in  
2. Cost spikes from relying on a single paid endpoint

## What I built

- A `claude-free` command (interactive picker UI in terminal)
- Multiple provider support:
  - NVIDIA NIM models
  - OpenRouter free models
  - Ollama local fallback
- Key-pool rotation per provider (so usage can continue when a single key hits limits)
- Local secrets split (`~/.claude-keys.zsh`) + shell routing logic (`~/.zshrc`)

## Current model menu includes

- NVIDIA:
  - `deepseek-ai/deepseek-v3.2`
  - `moonshotai/kimi-k2-instruct`
  - `z-ai/glm4.7`
- OpenRouter:
  - `stepfun/step-3.5-flash:free`
  - `z-ai/glm-4.5-air:free`
  - `nvidia/nemotron-3-super-120b-a12b:free`
  - `nvidia/nemotron-3-nano-30b-a3b:free`
- Ollama:
  - `qwen3.5:4b` on `localhost:11444`

## Why this was worth doing

- Faster experimentation with model choice per task
- Better resilience when one provider/model/key is unavailable
- Lower cost pressure by using free tiers + local fallback intentionally
- Cleaner operational setup by separating key storage from shell logic

## Auth-conflict cleanup (what I changed)

Auth conflicts can happen if both token + API key are set together.  
I switched the launcher flow to use provider API key + base URL cleanly, and unset conflicting token paths for this workflow.

Concretely, the router mode launches with only:
- `ANTHROPIC_API_KEY` (provider key)
- `ANTHROPIC_BASE_URL` (NVIDIA / OpenRouter URL)

and it avoids `ANTHROPIC_AUTH_TOKEN` to prevent the “token + API key are set” conflict prompt.

## What’s next

I’m now exploring **Claudish-style integration** so model selection can become automatic based on prompt type/intent (instead of manual menu selection each run).

If you’ve implemented prompt-aware model routing in production, I’d love to compare notes on:

- routing heuristics
- fallback order design
- guardrails for cost + latency

