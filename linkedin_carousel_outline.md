# LinkedIn Carousel Outline: Multi-Provider Claude Code Routing

## Slide 1 — Hook
**Title:** I stopped using a single-model coding setup  
**Copy:** Built a multi-provider Claude Code workflow with NVIDIA + OpenRouter + Ollama fallback.

## Slide 2 — Problem
**Title:** Why this was needed  
**Copy:**
- One provider = one failure domain
- Cost unpredictability
- Hard to pick the best model per task

## Slide 3 — Architecture at a glance
**Title:** How the setup works  
**Copy:**
- `~/.zshrc` = routing + model picker
- `~/.claude-keys.zsh` = provider key pools
- `claude-free` = launch and select model/provider
- Ollama local fallback on `localhost:11444`

## Slide 4 — Model picker UX
**Title:** `claude-free` terminal menu  
**Copy:**
- NVIDIA options
- OpenRouter options
- Ollama local option
- Select and launch in one step

## Slide 5 — Key rotation strategy
**Title:** Handling free-tier limits  
**Copy:**
- Multiple keys per provider in arrays
- Rotate keys per launch
- Continue working if one key is limited

## Slide 6 — Providers and model examples
**Title:** Current model catalog  
**Copy:**
- NVIDIA: DeepSeek V3.2, Kimi K2 Instruct, GLM4.7
- OpenRouter: Step 3.5 Flash free, GLM 4.5 Air free, Nemotron free variants
- Ollama: qwen3.5:4b

## Slide 7 — Auth conflicts + key prompts
**Title:** “token + key” conflicts are solvable  
**Copy:**
- In router mode, set only `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL`
- Avoid setting `ANTHROPIC_AUTH_TOKEN` (prevents token+key conflict prompt)
- For Ollama, explicitly unset both token and API key before launching

## Slide 8 — Impact
**Title:** What improved  
**Copy:**
- Better reliability across outages/limits
- Lower cost pressure
- Faster iteration by choosing model per task

## Slide 9 — What’s next
**Title:** Claudish-style auto routing  
**Copy:**
- Move from manual picker to prompt-aware auto model selection
- Route by task type, complexity, and latency/cost targets

## Slide 10 — CTA
**Title:** Looking for builders to compare notes  
**Copy:**
- How are you handling model routing in dev workflows?
- What fallback heuristics are working for you?

---

## Caption to pair with carousel (optional)
I rebuilt my Claude Code workflow to avoid single-provider bottlenecks: multi-provider routing (NVIDIA + OpenRouter), key rotation, and local Ollama fallback. Next step is automatic model selection based on prompt intent (Claudish-style routing). If you’ve built similar systems, I’d love to compare architecture and heuristics.

