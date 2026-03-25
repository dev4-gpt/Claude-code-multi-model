# Claude Code setup (Mac, zsh) — multi-provider + model picker

This is the earlier draft. The canonical, finalized version is now in `README.md`.

This repo doesn’t depend on Claude Code, but this document explains how **your machine** is configured to run **Claude Code** with:

- **NVIDIA NIM** models (free tier keys)
- **OpenRouter** free models (plus any other OpenRouter models you enable)
- **Ollama (local)** fallback (currently `qwen3.5:4b`)
- A **menu UI** (`claude-free`) to pick a model/provider at launch
- **Key rotation** across multiple keys per provider

> Important: This setup is shell-based. It applies anywhere you open a Terminal (it is not project-scoped).

---

## 0) Prereqs

### Node.js
Claude Code is distributed via npm. Install Node.js (LTS) from [nodejs.org](https://nodejs.org), then verify:

```bash
node --version
npm --version
```

---

## 1) Install / update Claude Code

Install:

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

Update:

```bash
claude --update
```

---

## 2) Install Ollama (local fallback)

Install (macOS):

```bash
brew install ollama
```

Verify:

```bash
ollama --version
```

List installed models:

```bash
ollama list
```

Current local model used by this setup:

- `qwen3.5:4b`

---

## 3) Ollama port (this setup uses 11444)

This setup expects Ollama at:

- `http://localhost:11444`

If your Ollama server is on the default port `11434`, either change the port to match or change the URLs in your shell config.

Quick check:

```bash
OLLAMA_HOST=http://localhost:11444 ollama list
```

Start the server (if needed):

```bash
ollama serve
```

---

## 4) Shell configuration files

### Main file
- `~/.zshrc`

This contains:
- the **model lists**
- the `claude-free` **picker UI**
- the `claude-local` shortcut
- logic to load keys from the keys file
- auth-conflict-safe launch behavior (`ANTHROPIC_AUTH_TOKEN` is unset in this flow)

### Keys file (secrets)
- `~/.claude-keys.zsh`

This contains **only** your API keys in arrays:
- `_NVIDIA_KEYS=(...)`
- `_OPENROUTER_KEYS=(...)`
- `_GROQ_KEYS=(...)` (optional; can be empty)

The picker rotates through these keys automatically.

---

## 5) Put your keys in the keys file

Edit:

```bash
nano ~/.claude-keys.zsh
open -R ~/.claude-keys.zsh
```

Example structure:

```zsh
_NVIDIA_KEYS=("nvapi-REAL_KEY_1" "nvapi-REAL_KEY_2")
_OPENROUTER_KEYS=("sk-or-REAL_KEY_1" "sk-or-REAL_KEY_2")
_GROQ_KEYS=()  # optional
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## 6) Configure which models appear in the menu

Edit `~/.zshrc` and update these arrays:

- `_NVIDIA_MODELS=(...)`
- `_OPENROUTER_MODELS=(...)`
- `_OLLAMA_MODELS=(...)`

Examples currently included:

### NVIDIA
- `deepseek-ai/deepseek-v3.2`
- `moonshotai/kimi-k2-instruct`
- `z-ai/glm4.7`

### OpenRouter
- `stepfun/step-3.5-flash:free`
- `z-ai/glm-4.5-air:free`
- `nvidia/nemotron-3-super-120b-a12b:free`
- `nvidia/nemotron-3-nano-30b-a3b:free`

### Ollama
- `qwen3.5:4b`

---

## 7) Daily usage

### A) Interactive menu (recommended)

```bash
claude-free
```

- Shows a numbered menu of NVIDIA / OpenRouter / Ollama models
- Rotates keys (NVIDIA/OpenRouter) each time you pick a model from that provider
- Uses only `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL` for remote providers (no token)

### B) Local-only shortcut

```bash
claude-local
```

Runs Claude Code against:
- Ollama at `http://localhost:11444`
- model `qwen3.5:4b`

---

## 8) Finder shortcuts (reveal files)

Reveal `~/.zshrc`:

```bash
open -R ~/.zshrc
```

Reveal `~/.claude-keys.zsh`:

```bash
open -R ~/.claude-keys.zsh
```

Or open your home folder and show hidden files:

```bash
open ~
```

Then press `Cmd+Shift+.` in Finder.

---

## 9) Auth prompts and troubleshooting

### A) Prompt: "Detected a custom API key in your environment"

When launching **NVIDIA/OpenRouter** via `claude-free`, choose:

- **Yes** (expected) — because this setup intentionally injects provider keys for routed calls.

When launching **Ollama** via `claude-local` or the Ollama option in `claude-free`, no API key is needed.

### B) Prompt: "Both token and API key are set" (auth conflict)

This means both `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` are active at once.
The current shell setup avoids this by unsetting token in provider-routed launches.

If you still see it:

```bash
unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_API_URL
source ~/.zshrc
```

Check active variables:

```bash
env | rg "^ANTHROPIC_"
```

### C) Model access error

If a selected model fails (not found / no access), choose a different model in the picker.
Provider free tiers and model availability can change.

---

## 10) Security notes

- Treat any API key you pasted into chat/screenshot as **compromised**; rotate it in the provider dashboard.
- Avoid committing keys to git. (This repo is not a git repo currently, but the advice still applies.)
- Keep secrets in `~/.claude-keys.zsh` only; don’t share it.

