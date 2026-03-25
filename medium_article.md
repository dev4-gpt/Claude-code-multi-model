# I Built a Multi-Provider Claude Code Router (NVIDIA + OpenRouter + Ollama) on macOS

One of the first “real life” problems you hit when building with LLMs is provider lock-in.

Early on, it’s easy to pick “the best model right now” and wire it into your workflow. But the minute a free-tier key hits a limit (or a model is temporarily unavailable), everything slows down. And when your goal is shipping code, waiting on the right backend is the worst kind of failure.

So I built a small router for **Claude Code** on macOS that can switch between:

- **NVIDIA NIM** free-tier models
- **OpenRouter** free-tier models
- **Ollama** as a local fallback (`qwen3.5:4b` via `http://localhost:11444`)

The result is a terminal workflow where I can pick *provider + model* on demand, with key rotation and a local escape hatch.

## Why this was worth doing

In practice, a single provider is a single failure domain:

- Free-tier accounts get rate-limited
- Model availability changes
- Your “default” model is rarely the right model for every task

I wanted something that gave me three capabilities at the same time:

1. **Model choice without rewiring** my workflow
2. **Fallback behavior** when one provider/key is constrained
3. **Cost control** by using free tiers intentionally and falling back to local

## The core idea: route requests from your shell

Instead of relying on one Claude Code config or logging into one provider inside Claude itself, I moved the routing logic into my shell environment.

Concretely:

- `claude-free` is an interactive terminal menu
- I define model catalogs in `~/.zshrc`
- I keep provider keys in a separate file: `~/.claude-keys.zsh`
- `claude-free` launches Claude Code with:
  - `ANTHROPIC_BASE_URL` set to the chosen provider
  - `ANTHROPIC_API_KEY` set to the next key from the matching provider key pool
  - `claude --model <chosen-model-id>` for the selected model

This keeps the “router” simple and transparent: model and provider are just parameters to `claude`.

## Setup (high level)

### 1) Install Claude Code (and verify)
```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 2) Install Ollama and ensure it runs on the port the router expects
This setup expects:
- `http://localhost:11444`

```bash
brew install ollama
ollama serve
```

If your Ollama runs on a different port, update the router block accordingly.

### 3) Add the router block to `~/.zshrc`
The exact block is included in this repo:
- `zshrc_claude_router_block.txt`

Reload:
```bash
source ~/.zshrc
```

### 4) Put your provider keys in `~/.claude-keys.zsh`
Do not store keys in `~/.zshrc`. Instead:
```bash
nano ~/.claude-keys.zsh
```

This repo includes a redacted template:
- `claude-keys.example.zsh`

## Key rotation: how I keep the workflow alive

Free-tier keys don’t last forever. My router rotates through multiple keys by provider.

Every time I launch a provider selection from the menu, the helper function advances an index for that provider’s key pool. That means if one key starts failing (rate limit / quota), the next run automatically tries the next key.

It’s not “fully automatic” orchestration yet, but it removes the worst annoyance: manually editing keys and relaunching.

## The auth-conflict lesson (and the real fix)

This part surprised me the most.

Claude Code started showing prompts and warnings like:

- “Detected a custom API key…”
- “Auth conflict: both token and API key are set”

The important distinction:

- In this router mode, I intentionally set `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` for NVIDIA/OpenRouter.
- The “auth conflict” prompt happens when `ANTHROPIC_AUTH_TOKEN` is also set in the same launch environment.

My fix was to make the router launch flow auth-conflict-safe:

- For NVIDIA/OpenRouter launches: set only `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL` and avoid `ANTHROPIC_AUTH_TOKEN`.
- For Ollama launches: explicitly unset both `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` so Claude Code sees a clean local-only environment.

After that, the router stopped failing in weird ways and became reliable.

## How I use it day-to-day

### Run the interactive picker
```bash
claude-free
```

It displays a numbered list grouped by provider (NVIDIA / OpenRouter / Ollama). I select one option and Claude Code starts immediately with the chosen model.

### Run local-only
```bash
claude-local
```

This is my “no networking, no waiting” shortcut.

## What’s next: prompt-aware routing with Claudish-style integration

Right now, the router is a manual menu.

Next, I’m moving toward **prompt-aware routing** (Claudish-style): automatically selecting the best provider/model tier based on what the user is asking for, then falling back if needed.

The vision:

- Use a stronger model for “planner” tasks
- Use a faster model for “draft and iterate” tasks
- Keep Ollama as the always-available fallback

If you’ve implemented prompt-aware model routing or multi-provider fallback in production, I’d love to compare notes on routing heuristics and guardrails for cost + latency.

## Repo notes

This entire setup is documented in `claude-routing-content`, including:
- the `~/.zshrc` router block
- the `~/.claude-keys.zsh` key-pool template
- the publish-ready drafts (LinkedIn + Medium + Substack)

