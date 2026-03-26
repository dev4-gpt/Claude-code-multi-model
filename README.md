# Claude Code Router (NVIDIA + OpenRouter + Ollama) — macOS

This repo documents a practical macOS setup for running **Claude Code** (`@anthropic-ai/claude-code`) while switching between:
- **NVIDIA NIM** (free-tier models via `integrate.api.nvidia.com`)
- **OpenRouter** (free-tier models via `openrouter.ai`)
- **Ollama** (local fallback; default `http://localhost:11434`, override with `_CLAUDE_OLLAMA_URL`)

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

### 2) Start Ollama (port must match `_CLAUDE_OLLAMA_URL`)
Default Ollama listens on **11434**. If you use a custom port (e.g. 11444), set `export _CLAUDE_OLLAMA_URL='http://localhost:11444'` in `~/.claude-keys.zsh` or before sourcing the router block.
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

## Command reference

- **`claude-local`**: Ollama-only (dummy `ollama`/`ollama` creds + `--bare`)
- **`claude-free`**: interactive provider/model picker (NVIDIA/OpenRouter/Ollama)
- **`claudish-nvidia`**: NVIDIA via Claudish translation (recommended if direct NVIDIA routing fails)
- **`claudish-nvidia-free`**: menu picker for NVIDIA models only (via Claudish)

## What files are involved

### Local (on your Mac)
- `~/.zshrc`
  - Contains the `claude-free` menu and routing logic
  - Calls Ollama at `_CLAUDE_OLLAMA_URL` (default `http://localhost:11434`)
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
- `scripts/verify-ollama-claude.sh`
  - Smoke test: `claude -p` against Ollama with dummy `ollama`/`ollama` credentials (takes ~20–40s first run)

## How the router works (what `claude-free` actually does)

When you run `claude-free`, you get a terminal menu of models grouped by provider:
- NVIDIA models (from `_NVIDIA_MODELS`)
- OpenRouter models (from `_OPENROUTER_MODELS`)
- Ollama models (from `_OLLAMA_MODELS`, currently `qwen3.5:4b`)

### NVIDIA note (direct vs Claudish)

NVIDIA integrate is **OpenAI-compatible** rather than Anthropic-compatible. This repo's current `claude-free` implementation routes NVIDIA selections through **`claudish-nvidia`** (translation proxy) for reliability.

If you run direct NVIDIA calls outside Claudish and they fail even though `curl` works, use:

- `claudish-nvidia` / `claudish-nvidia-free`

Claudish translates Anthropic ↔ OpenAI so Claude Code can drive NVIDIA reliably.

After you select an option, the launcher sets:
- `ANTHROPIC_BASE_URL` to the chosen provider URL
- For **NVIDIA/OpenRouter**: `ANTHROPIC_API_KEY` to the next key in the matching provider key pool (and we avoid mixing in a real Anthropic OAuth token — see below)
- For **Ollama**: dummy `ANTHROPIC_AUTH_TOKEN=ollama` and `ANTHROPIC_API_KEY=ollama` (required by Claude Code + Ollama’s Anthropic-compatible API — do **not** unset both or you get “Not logged in”)
- `claude --model <chosen-model-id>`

Auth behavior:
- For **NVIDIA/OpenRouter**, we do **not** set `ANTHROPIC_AUTH_TOKEN` (avoids “token + API key” conflicts with Anthropic Console auth)
- For **Ollama**, use the **dummy** token/key pair above (documented in [Ollama’s Claude Code integration](https://docs.ollama.com/integrations/claude-code))

Key rotation:
- Each time you pick NVIDIA/OpenRouter from the menu, `_claude_pick_key` advances an index variable for that provider, cycling through the keys in your secrets file.

`claude-free` launches **every** provider with **`claude --bare`** so interactive sessions do not fall back to Anthropic keychain/OAuth after `claude /logout` (same fix as `claude-local` for Ollama).

## Ollama URL / port
The router defaults to **`http://localhost:11434`** (standard Ollama). If nothing responds there but **11444** works, your Ollama is on a custom port — set once:

```bash
export _CLAUDE_OLLAMA_URL='http://localhost:11444'
```

Put that in `~/.claude-keys.zsh` (before or after sourcing is not required if the variable is set before `source ~/.zshrc` loads the block) or export it in `~/.zshrc` **above** the Claude block.

**Common mistake:** `ANTHROPIC_BASE_URL` pointed at the wrong host/port → requests never reach Ollama (hang or odd errors). Verify with `curl -s http://127.0.0.1:11434/api/tags` (adjust port).

### After `claude /logout` or `claude auth logout`
Anthropic session is cleared. **Do not** launch Ollama with `env -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_API_KEY` — that triggers **Not logged in**. Use dummy `ANTHROPIC_AUTH_TOKEN=ollama` and `ANTHROPIC_API_KEY=ollama` as in `zshrc_claude_router_block.txt`.

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

## Troubleshooting: “Max / Enterprise” or “please login”

**Unsetting `ANTHROPIC_API_KEY` in your shell does not, by itself, make Anthropic require Max or Enterprise.** That only clears local environment variables for that session. A tier message usually means Claude Code is taking the **official Anthropic account** path (subscription / Console) instead of **third-party API routing**.

### Anthropic tier vs free model routing (important distinction)

- **Free or cheap model routing** applies to **LLM API calls** when you launch with `ANTHROPIC_BASE_URL` pointing at NVIDIA, OpenRouter, or Ollama, plus the right key (or no key for Ollama).
- **Claude Code** is still Anthropic’s product. Some **features** (for example fetching URLs inside the app, or certain integrations) may still require **Anthropic login** or a **paid plan**, even when chat is routed to a free backend. That is separate from “which model answers.”

### Compare how you launch (reproduce)

| How you start | What should be set | Typical result |
|----------------|-------------------|----------------|
| `claude-free` or `claude-local` after `source ~/.zshrc` | `ANTHROPIC_BASE_URL` = provider URL; NVIDIA/OpenRouter use real provider keys; Ollama uses `AUTH_TOKEN=ollama` + `API_KEY=ollama` (dummy) | Completions go to the chosen provider; avoid unsetting Ollama dummy creds |
| Plain `claude` with no routing env | Often no `ANTHROPIC_BASE_URL` | Claude Code may behave like the normal Anthropic client; **Max / Enterprise / login** messages are more likely |

If you saw “Max or Enterprise” after opening the app a different way (desktop shortcut, bare `claude`, or after `/login`), compare with a **new terminal** where you only run `source ~/.zshrc` then `claude-free`.

### Check environment before starting Claude Code

In the **same** terminal session where you will run `claude-free` or `claude-local`:

```bash
source ~/.zshrc
env | rg '^ANTHROPIC_'
```

- If you expect **NVIDIA/OpenRouter** but `ANTHROPIC_BASE_URL` is missing, routing is not active.
- If you see a stray **`sk-ant-...`** in `ANTHROPIC_API_KEY` when you expected `nvapi-` / `sk-or-`, something else (shell export, IDE, or saved config) is overriding your keys — clear and reload:

```bash
unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_API_URL
source ~/.zshrc
```

### Claude Code version

Record your CLI version when reporting odd auth behavior:

```bash
claude --version
```

Example output from a typical install: `2.1.83 (Claude Code)`. After an `npm install -g @anthropic-ai/claude-code` upgrade, auth or tier messaging can change; check the package [release history on npm](https://www.npmjs.com/package/@anthropic-ai/claude-code) if needed.

### “Not logged in · Please run /login” with Ollama (`claude-local`)

**Installing** `@anthropic-ai/claude-code` from npm is free; that only puts the **CLI on your machine**. It does **not** mean Anthropic waives **in-app auth** for every mode. After `claude /logout`, the interactive UI often tries **Anthropic OAuth / keychain** again unless you force API-key-only mode.

**Fix (two parts):**

1. **Dummy Ollama credentials** (do not `env -u` both vars):  
   `ANTHROPIC_AUTH_TOKEN=ollama` and `ANTHROPIC_API_KEY=ollama` with `ANTHROPIC_BASE_URL` pointing at Ollama ([Ollama’s Claude Code docs](https://docs.ollama.com/integrations/claude-code)).

2. **Interactive sessions:** add **`--bare`**. In `claude --help`, `--bare` means Anthropic auth is **only** via `ANTHROPIC_API_KEY` — **OAuth and keychain are not read**. Without `--bare`, typing in the TUI can still show **Not logged in** even when `--model` shows `qwen3.5:4b`.

```bash
ANTHROPIC_AUTH_TOKEN=ollama ANTHROPIC_API_KEY=ollama ANTHROPIC_BASE_URL=http://localhost:11434 \
  claude --bare --model qwen3.5:4b
```

Copy the updated `claude-local` / Ollama branch from [`zshrc_claude_router_block.txt`](zshrc_claude_router_block.txt) into your `~/.zshrc` (it includes `--bare` for Ollama), then `source ~/.zshrc`.

**Tradeoff:** `--bare` is a slimmer mode (see `claude --help`: fewer IDE/hooks features). For full-fat UI **and** Ollama-only, Anthropic’s product may still push `/login` in some builds — then use `-p` / scripts or another client for local models.

**Quick non-interactive check** (requires Ollama running and the model pulled):

```bash
./scripts/verify-ollama-claude.sh
```

Some features (e.g. fetching a URL inside Claude Code) may still ask for `/login` — that is separate from the Ollama **chat** backend.

## Security
- Treat any key you paste into chat/screenshot as compromised and rotate it.
- Keep real keys only in `~/.claude-keys.zsh`.
- Do not commit secrets to git.

## What’s next: Claudish integration
The next step is moving from a manual menu to **prompt-aware routing** (Claudish-style), where we choose the best provider/model based on what the user asks, and then fall back automatically.

The goal: “tell me what you’re working on” and let the router decide the model tier (planner vs coder vs fast fallback).

