# Build a “Claude Code Router” so your dev workflow doesn’t die on one provider

I didn’t set out to build infrastructure.

I just wanted a fast, reliable way to use **Claude Code** for coding tasks on my Mac, without feeling like my entire workflow depended on one provider/model/key.

What made this urgent wasn’t “cost” in the abstract. It was the very specific dev reality: you sit down to ship, you pick a model, and then—because it’s a free tier or a quota bucket—you hit a rate limit and your whole session turns into waiting.

So I built a router.

Not a distributed system. Just a practical shell-based workflow that lets me switch providers and models while keeping keys rotated and keeping Ollama ready as a local fallback.

## The setup in one sentence

`claude-free` is a terminal menu that launches Claude Code against NVIDIA or OpenRouter (with rotating keys), and falls back to local Ollama (`qwen3.5:4b`) when things aren’t available.

## Why I didn’t just pick one “best” model

There are a few reasons “one model” stopped working for me:

1. **Availability is not stable**
   Models and free endpoints come and go. Even when something works at 10am, it may be capped by 2pm.

2. **Different tasks want different traits**
   Sometimes I need speed. Sometimes I need reasoning depth. Sometimes I want a local run that feels “instant.”

3. **I don’t want to babysit keys**
   If you rotate keys manually, you end up turning a workflow into an ops job.

## The architecture: move routing into the shell

The key decision was to treat Claude Code like an execution engine, and do the routing before it starts.

In my workflow:

- `~/.claude-keys.zsh` holds provider key pools
- `~/.zshrc` contains the menu + the launcher logic
- `claude-free` asks me which model I want
- the launcher sets:
  - `ANTHROPIC_BASE_URL` (provider endpoint)
  - `ANTHROPIC_API_KEY` (the next key from the chosen provider pool)
  - `claude --model <model-id>` (so I can keep multiple models)
- Ollama is always the last resort (`http://localhost:11444`)

This separation keeps things clean: the router is configurable, but secrets stay in one place.

## The part that almost broke everything: auth prompts + conflicts

If you use Claude Code with custom providers, you’ll eventually see messages like:

- “Detected a custom API key in your environment”
- “Auth conflict: both token and API key are set”

When I first encountered these prompts, I assumed it was an authentication “bug” in the router.

It wasn’t.

It was my mental model being out of sync with how Claude Code determines auth state.

In router mode, I was intentionally injecting a provider API key. That means Claude Code will legitimately ask for approval to use the key.

But the real problem was when the environment had both:

- `ANTHROPIC_AUTH_TOKEN` (Claude Console / Anthropic token flow)
- `ANTHROPIC_API_KEY` (provider key flow)

That “token + key” combination triggers the conflict warning.

So the fix was straightforward:

- for NVIDIA/OpenRouter launches: don’t set `ANTHROPIC_AUTH_TOKEN` at all
- for Ollama launches: explicitly unset `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` before starting Claude Code

Once that cleanup was in place, the router stopped behaving like it was randomly switching auth modes.

## How key rotation actually works

Rotation is intentionally simple.

For each provider (NVIDIA and OpenRouter), I keep an array of keys in `~/.claude-keys.zsh`.

Every time I launch a provider model from `claude-free`, the helper function advances an index for that provider’s key pool. Next launch uses the next key.

It’s not “automatic fallback within one session,” but it’s exactly what I wanted operationally: if one key stops working, the next run continues with the next key.

## The “fallback” philosophy: keep Ollama ready

Ollama is the local escape hatch.

In my setup, Ollama runs at `http://localhost:11444` and the local model is `qwen3.5:4b`.

If all remote keys are capped or unavailable, the local option keeps me moving without waiting on external services.

## A note on security (please take this seriously)

If you paste real API keys anywhere (including chat screenshots), assume they may be exposed.

In this workflow:

- never put real keys in `~/.zshrc`
- keep real keys only in `~/.claude-keys.zsh`
- treat any previously shared keys as compromised and rotate them in your provider dashboard

The repo includes:
- a redacted example file (`claude-keys.example.zsh`)
- the exact zsh router block you can copy into your shell

## What’s next: Claudish-style prompt-aware routing

Right now, `claude-free` is a manual menu.

My next step is to move from “human chooses model” to “the router chooses model.”

That’s where **Claudish-style integration** comes in.

The idea is to parse what you’re asking (planner vs coder vs quick rewrite), then choose:

- the best remote provider/model for the job
- a fallback order if the first tier fails
- Ollama as the final always-available layer

If you’ve built prompt-aware model routing, I’d love to compare:

- routing heuristics
- cost/latency guardrails
- how you decide when to escalate to a stronger model

## If you want to try it

Start here:

1. Install Claude Code
2. Install Ollama
3. Put keys in `~/.claude-keys.zsh`
4. Add the router block to `~/.zshrc`
5. Run `claude-free`, pick a model, and iterate

Everything I used and how it fits together is documented in this repo.

