# Local AI Agents Guide

A comprehensive reference for running AI coding agents locally and with cloud APIs, covering Ollama, aider, opencode, and pi. Written for future-you when you get a machine with more RAM.

## Table of Contents

- [Ollama (Local Model Server)](#ollama-local-model-server)
- [Aider (AI Pair Programmer)](#aider-ai-pair-programmer)
- [OpenCode (AI Coding Agent)](#opencode-ai-coding-agent)
- [Pi (Minimal Extensible Agent)](#pi-minimal-extensible-agent)
- [Gastown Integration](#gastown-integration)
- [Choosing the Right Tool](#choosing-the-right-tool)
- [Hardware Planning](#hardware-planning)

---

## Ollama (Local Model Server)

Ollama is the foundation — it serves LLMs locally on your Mac, exposing an OpenAI-compatible API that aider, opencode, and pi can all talk to.

### Quick Start

```bash
# Start the server (listens on localhost:11434)
ollama serve

# Pull a model
ollama pull qwen2.5-coder:7b      # 6GB, good for 18GB machine
ollama pull qwen2.5-coder:14b     # 11GB, needs 32GB machine
ollama pull llama3.3:70b           # 46GB, needs 64GB+ machine

# Run interactively (for testing)
ollama run qwen2.5-coder:7b

# List downloaded models
ollama list

# Remove a model
ollama rm qwen2.5-coder:7b
```

### The OpenAI-Compatible API

This is what makes Ollama universal — any tool that speaks OpenAI's API format can use it:

```
Base URL:  http://localhost:11434/v1/
Endpoints: /v1/chat/completions, /v1/completions, /v1/models, /v1/embeddings
API Key:   "ollama" (anything works, it's local)
```

Test it:
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [{"role": "user", "content": "Write fizzbuzz in Go"}],
    "stream": false
  }'
```

### Configuration

Set via environment variables (add to your `zsh.nix` `sessionVariables` when ready):

| Variable | Default | Purpose |
|---|---|---|
| `OLLAMA_HOST` | `127.0.0.1:11434` | Bind address |
| `OLLAMA_MODELS` | `~/.ollama/models` | Model storage path |
| `OLLAMA_NUM_PARALLEL` | `1` | Concurrent requests per model |
| `OLLAMA_MAX_LOADED_MODELS` | `3` | Models held in memory simultaneously |
| `OLLAMA_KEEP_ALIVE` | `5m` | How long to keep model loaded after last request |
| `OLLAMA_FLASH_ATTENTION` | off | Enable Flash Attention (faster inference) |
| `OLLAMA_KV_CACHE_TYPE` | `f16` | KV cache precision (`q8_0` halves cache memory) |

### Performance Tuning for Apple Silicon

```bash
# Recommended for any machine
export OLLAMA_FLASH_ATTENTION=1       # faster inference
export OLLAMA_KV_CACHE_TYPE=q8_0      # halves KV cache memory
export OLLAMA_KEEP_ALIVE=30m          # avoid reload latency

# For bigger machines (32GB+)
export OLLAMA_NUM_PARALLEL=4          # serve multiple requests
```

Apple Silicon advantages:
- **Unified memory** — GPU and CPU share the same RAM, no VRAM bottleneck
- **Metal acceleration** — automatic on all Apple Silicon, all GPU cores utilized
- **MLX backend** (Ollama 0.19+) — up to 93% faster decode on Apple Silicon
- MLX requires 32GB+ unified memory to activate

Expected performance (Apple Silicon, Q4_K_M quantization):

| Model Size | Tokens/sec | RAM Needed |
|---|---|---|
| 7-8B | 28-35 tok/s | ~6 GB |
| 14B | 18-25 tok/s | ~11 GB |
| 32B | 10-15 tok/s | ~22 GB |
| 70B | 5-8 tok/s | ~46 GB |

### Custom Modelfiles

Create custom model configurations:

```dockerfile
# Save as Modelfile
FROM qwen2.5-coder:14b

# Tune for coding
PARAMETER temperature 0.3
PARAMETER num_ctx 16384
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1

SYSTEM """You are a senior software engineer. Write clean,
well-tested code. Prefer functional patterns. Always explain
your reasoning before providing code."""
```

```bash
ollama create my-coder -f ./Modelfile
ollama run my-coder
```

### Recommended Coding Models by RAM Tier

**18GB (M3 base — your current machine):**
- `qwen2.5-coder:7b` — best coding model under 8B params
- `qwen3:7b` — highest HumanEval score (76.0) at this size
- `codellama:7b` — Meta's code-specific model

**32GB (M3 Pro/Max, M4 Pro):**
- `qwen2.5-coder:14b` — best mid-range coding model, sweet spot
- `qwen3:14b` — excellent reasoning + code
- `deepseek-coder:6.7b` — lighter alternative, strong multi-language

**64GB (M4 Max):**
- `qwen3:32b` — excellent quality
- `gemma3:27b` — strong reasoning
- `llama3.3:70b` — GPT-4-class (tight fit, works with q4_K_M)
- `deepseek-r1:70b` — chain-of-thought reasoning, great for debugging

**128GB (M4 Ultra):**
- `llama3.3:70b` with massive context windows
- `qwen2.5:72b` — top-tier local
- Multiple models simultaneously

### Important: Context Window

Ollama defaults to a **2K context window** and **silently discards** anything beyond it. This is way too small for coding agents. Always increase it:

```bash
# Per-session
OLLAMA_CONTEXT_LENGTH=16384 ollama serve

# Or in a Modelfile
PARAMETER num_ctx 16384
```

For agentic coding, you want at least 8K, ideally 16K-32K.

---

## Aider (AI Pair Programmer)

Aider is the most mature AI pair programming tool. It edits files in your git repo directly, auto-commits changes, and understands your codebase via a repository map built with tree-sitter.

### Quick Start

```bash
# With Claude (your default)
export ANTHROPIC_API_KEY=sk-ant-...
aider

# With Ollama
export OLLAMA_API_BASE=http://127.0.0.1:11434
aider --model ollama_chat/qwen2.5-coder:14b

# With OpenAI
export OPENAI_API_KEY=sk-...
aider --model gpt-4o
```

### Configuration File

Aider looks for `.aider.conf.yml` in: home directory, git repo root, then current directory. Later files override earlier ones.

```yaml
# ~/.aider.conf.yml — global defaults

# ── Model selection ──────────────────────────────────────────────
model: claude-3-5-sonnet-20241022     # main model (the one doing edits)
weak-model: claude-3-5-haiku-20241022 # cheap model for commit msgs + summaries
editor-model: claude-3-5-sonnet-20241022  # model for architect mode's editor

# ── Edit behavior ────────────────────────────────────────────────
edit-format: diff        # diff | whole | udiff | architect
architect: false         # two-model mode (see below)
auto-accept-architect: true

# ── Git integration ──────────────────────────────────────────────
auto-commits: true       # auto-commit every change aider makes
dirty-commits: true      # commit your uncommitted changes first
attribute-co-authored-by: true
git-commit-verify: false # skip pre-commit hooks (faster)

# ── Repository map ───────────────────────────────────────────────
map-tokens: 1024         # token budget for the repo map
map-refresh: auto        # auto | always | files | manual

# ── Linting & testing ───────────────────────────────────────────
auto-lint: true
lint-cmd: "python: flake8"
lint-cmd: "javascript: eslint"
auto-test: false
test-cmd: "pytest"

# ── Display ──────────────────────────────────────────────────────
dark-mode: true
stream: true
pretty: true
code-theme: monokai
vim: true                # vim keybindings in input

# ── Context ──────────────────────────────────────────────────────
max-chat-history-tokens: 4096
read:                    # always-loaded read-only context
  - CONVENTIONS.md
  - docs/architecture.md
```

### Ollama-Specific Configuration

Create `.aider.model.settings.yml` alongside your config:

```yaml
# Critical: tell aider about Ollama's context window
- name: ollama_chat/qwen2.5-coder:14b
  edit_format: diff
  weak_model_name: ollama_chat/qwen2.5-coder:7b
  use_repo_map: true
  extra_params:
    num_ctx: 16384       # MUST match your Ollama context setting

- name: ollama_chat/qwen2.5-coder:7b
  edit_format: whole     # smaller models do better with whole-file edits
  use_repo_map: true
  extra_params:
    num_ctx: 8192
```

### In-Chat Commands

| Command | What it does |
|---|---|
| `/add <file>` | Add files to chat (aider can now edit them) |
| `/drop <file>` | Remove files from chat (free up context) |
| `/read-only <file>` | Add as reference only (can't edit) |
| `/ask <question>` | Ask without making edits |
| `/code <request>` | Request code changes (default mode) |
| `/architect` | Switch to architect mode |
| `/diff` | Show diff of changes since last message |
| `/undo` | Undo the last aider commit |
| `/commit` | Commit changes you made outside aider |
| `/run <cmd>` | Run a shell command, optionally add output to chat |
| `/test <cmd>` | Run tests, send failures to chat for fixing |
| `/lint` | Lint and fix in-chat files |
| `/tokens` | Report current context usage |
| `/model <name>` | Switch the main model |
| `/clear` | Clear chat history |
| `/map` | Show the repo map |
| `/web <url>` | Scrape a webpage into chat |
| `/voice` | Record and transcribe voice input |
| `/ls` | List files and which are in chat |
| `/save` | Save commands to reconstruct this session |
| `/exit` | Quit |

### Edit Formats

| Format | Best for | How it works |
|---|---|---|
| **diff** | Strong models (Claude, GPT-4o) | Search/replace blocks — fast, token-efficient |
| **whole** | Weaker/small models | Returns entire updated file — simple but costly |
| **udiff** | GPT-4 Turbo | Unified diff format |
| **architect** | Reasoning models (o1, o3, R1) | Two-phase: architect proposes, editor applies |

Aider auto-selects the optimal format for known models. Override with `--edit-format`.

### Architect Mode

Splits work between two models:

1. **Architect** (strong reasoner): analyzes the problem, proposes a solution
2. **Editor** (strong coder): translates the proposal into precise file edits

```bash
# Pair a reasoning model with a coding model
aider --architect --model o3-mini --editor-model gpt-4o

# Or with local models
aider --architect --model ollama_chat/deepseek-r1:32b --editor-model ollama_chat/qwen2.5-coder:14b
```

Use architect mode when the reasoning model is great at thinking but bad at precise edits (common with o1, o3, DeepSeek R1).

### Repository Map

Aider's killer feature. It uses tree-sitter to parse your codebase and build a compact map of all classes, functions, methods, and their signatures. This map is sent with every request, so the LLM understands your codebase structure without needing every file in context.

- Uses a graph ranking algorithm to surface the most-referenced identifiers
- Dynamically sized to fit within `--map-tokens` budget
- The LLM can request additional files based on what it sees in the map
- Refresh with `/map-refresh`; view with `/map`

### Watch Mode (IDE Integration)

```yaml
watch-files: true
```

Drop AI comments in your editor:
```python
# AI! Fix the type error on line 42
# AI? What does this function do?
```

Aider picks them up automatically and processes them. Works with any editor/IDE.

### Tips

- **Only `/add` files that need editing** — the repo map handles awareness of everything else
- **Use `/drop` aggressively** — free context when done with a file
- **Use `/ask` before `/code`** — plan first, implement second
- **Use `/read-only` for reference files** — architecture docs, conventions, etc.
- **Break large tasks into small changes** — easier for the model, easier to `/undo`
- **Use `--cache-prompts` with Claude/DeepSeek** — caches system prompts, saves money

---

## OpenCode (AI Coding Agent)

OpenCode is an open-source, terminal-native AI coding agent with a rich TUI (panels, dialogs, session management). It's model-agnostic with 75+ provider support and has LSP integration.

**Note:** The original Go-based opencode was archived. The active project is the TypeScript rewrite by the SST team at [sst/opencode](https://github.com/sst/opencode).

### Quick Start

```bash
# With Claude
export ANTHROPIC_API_KEY=sk-ant-...
opencode

# With OpenAI
export OPENAI_API_KEY=sk-...
opencode

# Non-interactive (scripting)
opencode -p "Explain this codebase"
```

### Configuration

Config is JSON at `./opencode.json` (project), `~/.config/opencode/opencode.json` (global), or `$OPENCODE_CONFIG`.

```json
{
  "providers": {
    "anthropic": {
      "apiKey": "sk-ant-...",
      "disabled": false
    },
    "openai": {
      "apiKey": "sk-...",
      "disabled": false
    }
  },
  "agents": {
    "coder": {
      "model": "claude-sonnet-4-5",
      "maxTokens": 16000,
      "reasoningEffort": "high"
    },
    "task": {
      "model": "claude-sonnet-4-5",
      "maxTokens": 5000
    },
    "title": {
      "model": "claude-3-5-haiku",
      "maxTokens": 80
    }
  },
  "shell": {
    "path": "/bin/zsh",
    "args": ["-l"]
  },
  "lsp": {
    "go": { "command": "gopls" },
    "typescript": { "command": "typescript-language-server", "args": ["--stdio"] }
  },
  "mcpServers": {},
  "plugin": [],
  "autoCompact": true
}
```

### Ollama Setup

```json
{
  "provider": {
    "ollama": {
      "name": "Ollama",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen2.5-coder:14b": {
          "name": "Qwen 2.5 Coder 14B",
          "toolCall": true,
          "contextLength": 16384
        }
      }
    }
  }
}
```

**Important:** The model must support tool calling for opencode's agentic features. Known working: Qwen 2.5 Coder, Llama 3.1/3.3, Mistral Large.

### Keyboard Shortcuts

| Key | Action |
|---|---|
| `Ctrl+N` | New session |
| `Ctrl+A` | Switch session |
| `Ctrl+O` | Model selection |
| `Ctrl+K` | Command dialog |
| `Ctrl+S` | Send message (in editor) |
| `Ctrl+E` | Open external editor ($EDITOR) |
| `Ctrl+X` | Cancel generation |
| `Ctrl+L` | View logs |
| `i` | Focus editor (vim-style) |
| `Esc` | Close overlay / blur editor |
| `a` / `A` / `d` | Allow / Allow for session / Deny (permission dialog) |

### Built-in Tools

| Tool | Description |
|---|---|
| `glob` | Find files by pattern |
| `grep` | Search file contents with regex |
| `ls` | List directory |
| `view` | Read file contents |
| `write` | Write files |
| `edit` | Patch-based file editing |
| `patch` | Apply unified diffs |
| `bash` | Execute shell commands |
| `fetch` | Fetch URLs |
| `diagnostics` | Get LSP diagnostics |
| `sourcegraph` | Search code across public repos |
| `agent` | Run sub-tasks with a sub-agent |

### Agents

| Agent | Purpose |
|---|---|
| `coder` | Main coding assistant, full tool access |
| `task` | Sub-agent for focused sub-tasks |
| `plan` | Planning agent, restricted tool access |
| `title` | Session title generation |
| `summarizer` | Auto-compact summarization |

### opencode-claude-auth Plugin

Use your Claude Pro/Max subscription with opencode — no separate API key:

```json
{
  "plugin": ["opencode-claude-auth"]
}
```

Auto-installs via Bun at startup. Reads OAuth tokens from macOS Keychain. Supports multiple accounts and 1M context with Max subscription.

**Caveat:** Community workaround — Anthropic's ToS say Pro/Max tokens should only be used with official clients.

### Session Management

- SQLite-backed persistent storage
- Switch sessions with `Ctrl+A`
- Auto-compact at 95% context: summarizes and creates new session
- File change tracking and diff visualization

### Custom Commands

Create `.md` files in `~/.config/opencode/commands/` (global) or `.opencode/commands/` (project):

```markdown
---
description: Fix the GitHub issue
---
Fix issue #$ISSUE_NUMBER. Read the issue details, understand the problem, and implement a fix.
```

### Context Files

OpenCode auto-reads project context from: `CLAUDE.md`, `.cursorrules`, `opencode.md`, `.github/copilot-instructions.md`.

---

## Pi (Minimal Extensible Agent)

Pi is a minimal, open-source terminal coding agent by Mario Zechner. Its philosophy is aggressive extensibility — ship a tiny core (4 tools, ~1000-token system prompt) and let you build everything else via extensions.

Website: [shittycodingagent.ai](https://shittycodingagent.ai) (yes, really)

### Quick Start

```bash
# Install
npm install -g @mariozechner/pi-coding-agent

# With Claude
export ANTHROPIC_API_KEY=sk-ant-...
pi

# Or login via OAuth
pi
/login  # Select provider
```

### Why Pi?

Claude Code has a ~10,000-token system prompt with many built-in tools. Pi has ~1,000 tokens and 4 tools. Everything Claude Code bakes in, pi makes optional:

| Feature | Claude Code | Pi |
|---|---|---|
| Sub-agents | Built-in | Build via extension or tmux |
| Plan mode | TodoWrite | Write plans to files, or build via extension |
| MCP | Built-in | Add via extension |
| Permissions | Built-in prompts | Build via extension, or run in container |
| Background processes | Built-in | Use tmux |

The tradeoff: more of your context window goes to your actual work, but you build (or install) more yourself.

### The Four Core Tools

1. **`read`** — Read file contents
2. **`write`** — Write a complete file
3. **`edit`** — Targeted string-replacement edits
4. **`bash`** — Execute shell commands

Everything else is an extension.

### Configuration

Settings live at:
- `~/.pi/agent/settings.json` — global
- `.pi/settings.json` — project-local (overrides global)

Use `/settings` interactively or edit JSON directly.

Context files (`AGENTS.md` or `CLAUDE.md`) are loaded from `~/.pi/agent/`, parent directories, and the current directory. Replace the system prompt with `.pi/SYSTEM.md` or append to it with `APPEND_SYSTEM.md`.

### Ollama / Local Model Setup

Create `~/.pi/agent/models.json`:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        { "id": "qwen2.5-coder:7b" },
        { "id": "qwen2.5-coder:14b" },
        { "id": "llama3.3:70b" }
      ]
    }
  }
}
```

Set default in `~/.pi/agent/settings.json`:
```json
{
  "defaultProvider": "ollama",
  "defaultModel": "qwen2.5-coder:14b"
}
```

Switch models at runtime: `/model` (interactive picker) or `Ctrl+L`.

### Supported Providers

**OAuth (subscription-based):** Anthropic Claude Pro/Max, OpenAI ChatGPT Plus/Pro, GitHub Copilot, Google Gemini CLI.

**API key:** Anthropic, OpenAI, Azure OpenAI, Google Gemini, Google Vertex, Amazon Bedrock, Mistral, Groq, Cerebras, xAI, OpenRouter, and more.

**Local:** Ollama, vLLM, LM Studio — anything with an OpenAI-compatible API.

### Extension System

Extensions are TypeScript files in `~/.pi/agent/extensions/` (global) or `.pi/extensions/` (project). Loaded via jiti — TypeScript works without compilation. Hot-reload with `/reload`.

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // Block dangerous commands
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash" && event.input.command?.includes("rm -rf /")) {
      const ok = await ctx.ui.confirm("Danger!", "Allow rm -rf /?");
      if (!ok) return { block: true, reason: "Blocked by user" };
    }
  });

  // Register a custom tool
  pi.registerTool({
    name: "deploy",
    label: "Deploy",
    description: "Deploy to production",
    parameters: Type.Object({ env: Type.String() }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      // ... deployment logic ...
      return { content: [{ type: "text", text: `Deployed to ${params.env}` }], details: {} };
    },
  });

  // Register a slash command
  pi.registerCommand("stats", {
    description: "Show session stats",
    handler: async (args, ctx) => { ctx.ui.notify("Stats!", "info"); },
  });

  // Register a keyboard shortcut
  pi.registerShortcut("ctrl+d", {
    description: "Quick deploy",
    handler: async (ctx) => { /* ... */ },
  });
}
```

Events you can hook into (~20+): `session_start`, `tool_call`, `tool_result`, `agent_start`, `agent_end`, `turn_start`, `turn_end`, `context`, `before_provider_request`, `session_before_compact`, `session_compact`, `input`, `model_select`, `resources_discover`, `session_shutdown`, and more.

### Skills System

Skills follow the [Agent Skills standard](https://agentskills.io). They're on-demand capability packages — only the name and description are in the system prompt; full content loads when needed.

Place in `~/.pi/agent/skills/` or `.pi/skills/`:

```
my-skill/
  SKILL.md        # YAML frontmatter + instructions
  scripts/        # Helper scripts
  references/     # Detailed docs
```

```markdown
---
name: deploy-to-gcp
description: Deploy services to Google Cloud Platform
---
# GCP Deployment
## Steps
1. Check gcloud auth: `gcloud auth list`
2. ...
```

### Prompt Templates

Reusable prompts in `~/.pi/agent/prompts/` or `.pi/prompts/`. Filename becomes the command:

```markdown
# ~/.pi/agent/prompts/review.md
---
description: Review staged git changes
---
Review the staged changes (`git diff --cached`). Focus on: {{focus}}
```

Invoke with `/review focus="security and error handling"`.

### Running Modes

1. **Interactive** (default) — full TUI
2. **Print** (`pi -p "query"`) — print response and exit, also reads piped stdin
3. **JSON** (`pi --mode json`) — output all events as JSON lines
4. **RPC** (`pi --mode rpc`) — for process integration over stdin/stdout
5. **SDK** — embed in your own apps via `@mariozechner/pi-coding-agent`

### Sessions

Sessions are JSONL files with tree structure (branching in-place). Navigate with `/tree`, fork with `/fork`, compact with `/compact`. Auto-compaction on context overflow.

### Pi Packages

Share and install extensions, skills, prompts, and themes:

```bash
pi install npm:@foo/pi-tools
pi install git:github.com/user/repo
pi list
pi update
```

### oh-my-pi (omp) — The Batteries-Included Fork

[oh-my-pi](https://github.com/can1357/oh-my-pi) by @can1357 is a fork that adds everything pi intentionally omits:

- **Hashline edits** — every line gets a content hash, eliminating "string not found" errors
- **LSP integration** — 40+ languages, diagnostics, go-to-definition, references, rename
- **Sub-agents** — 6 bundled agents (explore, plan, designer, reviewer, task, quick_task)
- **Browser tool** — Puppeteer with stealth scripts
- **Python tool** — persistent IPython kernel
- **SSH tool** — persistent remote connections
- **Web search** — multi-provider (Exa, Brave, Jina, etc.)
- **MCP support** — stdio + HTTP with OAuth
- **Native Rust engine** — ripgrep internals, embedded bash, syntax highlighting
- **Commit tool** — agentic git with hunk-level staging
- **65+ themes**

Install: `bun install -g @oh-my-pi/pi-coding-agent`

Gastown also has `omp` as a built-in agent: `omp [built-in] omp --hook .omp/hooks/gastown-hook.ts`

**When to use omp over pi:** When you want everything out of the box. When to use pi: when you want to build your own stack from a minimal core.

---

## Gastown Integration

All four tools are registered (or can be) as Gastown agents. Here's how they connect:

### Currently Registered Agents

```
gt config agent list

aider-local [custom]    aider --model ollama/codellama --no-auto-commits
claude      [built-in]  claude --dangerously-skip-permissions
opencode    [built-in]  opencode
pi          [built-in]  pi -e .pi/extensions/gastown-hooks.js
omp         [built-in]  omp --hook .omp/hooks/gastown-hook.ts
```

### Assigning Agents to Roles

```bash
# Use local models for patrol agents (free), Claude for polecats (quality)
gt rig settings set my-rig role_agents.witness aider-local
gt rig settings set my-rig role_agents.refinery opencode-local
# polecats default to claude

# Or use cost tiers
gt config cost-tier economy   # patrols on Sonnet/Haiku, polecats on Opus

# Or go full local for a personal project
gt-personal config default-agent aider-local
```

### Agent Requirements for Gastown

For an agent to work with Gastown, it needs to:
1. Run in a terminal (tmux session)
2. Accept prompts and execute them
3. Support session hooks (SessionStart → `gt prime --hook`)
4. Be able to run shell commands (for `gt done`, `gt handoff`, `gt mail`, etc.)

Claude, opencode, and pi have the deepest integration (hooks, session management). Aider works but is more of a coding tool than a full agent — it's best for polecats (do work, commit, exit) rather than patrol roles (witness, refinery) that need persistent session management.

### Recommended Gastown Configuration

**Work town (Claude-primary, local for patrols when on bigger machine):**
```bash
gt config cost-tier economy                          # Sonnet for patrols, Opus for polecats
# After getting bigger machine:
gt rig settings set <rig> role_agents.witness pi      # pi watching the rig
gt rig settings set <rig> role_agents.refinery opencode  # opencode processing MQ
# polecats stay on claude for best coding quality
```

**Personal town (local-primary for cost savings):**
```bash
gt-personal config default-agent aider-local          # everything local by default
# Override specific rigs that need cloud quality:
gt-personal rig settings set important-project role_agents.polecat claude
```

---

## Choosing the Right Tool

| Dimension | Aider | OpenCode | Pi | Claude Code |
|---|---|---|---|---|
| **Best at** | Git-native pair programming | IDE-like TUI, multi-provider | Extensibility, minimal footprint | Deep Claude integration |
| **Git integration** | Best (auto-commit everything) | Basic | Basic | Good (on request) |
| **Local models** | Excellent (Ollama native) | Good (OpenAI-compat) | Excellent (any provider) | No |
| **Repo understanding** | Tree-sitter map (excellent) | LSP diagnostics | Extension-based | File reading |
| **Configuration** | YAML config files (rich) | JSON config (clean) | JSON + extensions (flexible) | settings.json (limited) |
| **Learning curve** | Medium | Low | High (but powerful) | Low |
| **Context efficiency** | Good | Good | Best (tiny system prompt) | Heavy (large system prompt) |
| **Extension system** | No | Plugins (npm) | Full TS extension API | Hooks + MCP |
| **Gastown fit** | Polecats (work + commit) | All roles | All roles (best hook support) | All roles (default) |

### Decision Framework

- **"I just want to code with AI locally"** → aider + Ollama
- **"I want a polished TUI with session management"** → opencode
- **"I want full control and will build my own tools"** → pi
- **"I want the best quality and don't care about cost"** → Claude Code
- **"I want free local coding on a beefy Mac"** → pi or aider + Ollama
- **"I want to mix local and cloud models in Gastown"** → pi for patrols, Claude for polecats

---

## Hardware Planning

### Your Current Machine (M3, 18GB)

Usable but constrained:
- Can run 7B models comfortably (qwen2.5-coder:7b)
- 14B is a squeeze (leaves little room for IDE + browser + tmux)
- Cloud APIs (Claude, GPT-4o) will be your primary for serious work

### What to Look For in the New Machine

**32GB** — The practical minimum for local AI coding:
- Runs 14B models with room to breathe
- Can load one model + full dev stack
- Good for: aider/pi with qwen2.5-coder:14b

**64GB** — The sweet spot:
- Runs 32B models comfortably, 70B in a pinch
- MLX backend activates (faster inference)
- Can keep a model loaded while running everything else
- Good for: all tools, most models, Gastown with local patrol agents

**128GB** — Future-proof:
- Runs 70B models with large context windows
- Multiple models simultaneously (patrol + worker)
- Good for: full Gastown stack running entirely local

**Recommendation:** 64GB minimum, 128GB if budget allows. The M4 Max with 128GB unified memory would let you run a 70B model for polecats and a 14B model for patrols simultaneously — a fully local Gastown setup that rivals cloud API quality.
