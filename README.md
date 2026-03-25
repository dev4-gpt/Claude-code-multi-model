# Claude Code Router (NVIDIA + OpenRouter + Ollama) — macOS

This repo documents a practical macOS setup for running **Claude Code** (`@anthropic-ai/claude-code`) while switching between:
- **NVIDIA NIM** (free-tier models via `integrate.api.nvidia.com`)
- **OpenRouter** (free-tier models via `openrouter.ai`)
- **Ollama** (local fallback via `http://localhost:11444`)

Instead of binding your workflow to one paid endpoint/model, you get:
1. A terminal menu (`claude-free`) to choose *provider + model*
2. Key rotation per provider (multiple API keys in a separate file)
3. An auth-conflict-safe launch flow (no `ANTHROPIC_AUTH_TOKEN` in this router mode)
4. A local shortcut (`claude-local`) for Ollama

## Quick start

### 1) Install prerequisites
```bash
# Node.js (LTS)
node --version
npm --version

# Claude Code
npm install -g @anthropic-ai/claude-code
claude --version

# Ollama
brew install ollama
ollama --version
```

### 2) Start Ollama (must match port 11444)
```bash
ollama serve
```

### 3) Create your local key pools
Edit your secrets file (do **not** commit real keys):
```bash
nano ~/.claude-keys.zsh
```
Use the example structure in `claude-keys.example.zsh`.

### 4) Load the router changes
Make sure your `~/.zshrc` contains the `claude-free` / `claude-local` block from:
- `zshrc_claude_router_block.txt` (this repo)

Then reload:
```bash
source ~/.zshrc
```

### 5) Use it
Pick a model/provider:
```bash
claude-free
```
Or run Ollama-only:
```bash
claude-local
```

## What files are involved

### Local (on your Mac)
- `~/.zshrc`
  - Contains the `claude-free` menu and routing logic
  - Calls Ollama at `http://localhost:11444`
  - Loads key pools from `~/.claude-keys.zsh`
  - Prevents auth conflicts by not setting `ANTHROPIC_AUTH_TOKEN`
- `~/.claude-keys.zsh` (secrets)
  - Defines key arrays:
    - `_NVIDIA_KEYS=("nvapi-...")`
    - `_OPENROUTER_KEYS=("sk-or-...")`
    - `_GROQ_KEYS=()` optional

### In this repo
- `claude-keys.example.zsh`
  - Redacted example of what `~/.claude-keys.zsh` should look like
- `zshrc_claude_router_block.txt`
  - Reference copy of the Claude router block you added to `~/.zshrc`

## How the router works (what `claude-free` actually does)

When you run `claude-free`, you get a terminal menu of models grouped by provider:
- NVIDIA models (from `_NVIDIA_MODELS`)
- OpenRouter models (from `_OPENROUTER_MODELS`)
- Ollama models (from `_OLLAMA_MODELS`, currently `qwen3.5:4b`)

After you select an option, the launcher sets:
- `ANTHROPIC_BASE_URL` to the chosen provider URL
- `ANTHROPIC_API_KEY` to the next key in the matching provider key pool
- `claude --model <chosen-model-id>`

Auth-conflict-safe behavior:
- In router mode, we intentionally **avoid** setting `ANTHROPIC_AUTH_TOKEN`
- For Ollama launches, we explicitly unset both `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` to keep the session clean

Key rotation:
- Each time you pick NVIDIA/OpenRouter from the menu, `_claude_pick_key` advances an index variable for that provider, cycling through the keys in your secrets file.

## Ollama port note (11444)
This setup expects Ollama at:
- `http://localhost:11444`

If your Ollama is on the default `11434`, update either:
- your Ollama server port, or
- the `http://localhost:11444` values in your `claude-local` and `claude-free` blocks.

## Auth prompts: what to expect

### “Detected a custom API key in your environment”
You will see a prompt the first time Claude Code encounters a custom `ANTHROPIC_API_KEY` value in this workflow.

In this router setup, choosing **Yes** is expected for NVIDIA/OpenRouter launches, because we intentionally inject provider keys via `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL`.

### “Auth conflict: token + API key are set”
If you ever see conflicts, it means both:
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_API_KEY`

are set in the same Claude Code launch environment.

To recover quickly:
```bash
unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_API_URL
source ~/.zshrc
```

Then rerun `claude-free`.

## Security
- Treat any key you paste into chat/screenshot as compromised and rotate it.
- Keep real keys only in `~/.claude-keys.zsh`.
- Do not commit secrets to git.

## What’s next: Claudish integration
The next step is moving from a manual menu to **prompt-aware routing** (Claudish-style), where we choose the best provider/model based on what the user asks, and then fall back automatically.

The goal: “tell me what you’re working on” and let the router decide the model tier (planner vs coder vs fast fallback).

