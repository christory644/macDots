# Gas City Guide

A comprehensive reference for configuring and operating Gas City, the open-source multi-agent orchestration SDK by Steve Yegge. Gas City is the successor to Gastown — same creator, rebuilt as a proper SDK with cleaner primitives.

## Table of Contents

- [Core Concepts](#core-concepts)
- [Installation](#installation)
- [Your Setup](#your-setup)
- [Quickstart](#quickstart)
- [Configuration (city.toml)](#configuration-citytoml)
- [Agents](#agents)
- [Rigs](#rigs)
- [Beads (Work Substrate)](#beads-work-substrate)
- [Formulas (Workflow Templates)](#formulas-workflow-templates)
- [Sessions](#sessions)
- [Mail & Messaging](#mail--messaging)
- [Orders (Periodic Dispatch)](#orders-periodic-dispatch)
- [Packs (Shareable Config)](#packs-shareable-config)
- [Supervision & Lifecycle](#supervision--lifecycle)
- [CLI Reference](#cli-reference)
- [Coming from Gastown](#coming-from-gastown)
- [Recommended City Configuration](#recommended-city-configuration)

---

## Core Concepts

Gas City replaces Gastown's directory-based role taxonomy with a small set of composable primitives:

| Primitive | What It Is | Gastown Equivalent |
|---|---|---|
| **City** | Top-level workspace directory with `city.toml` | Town |
| **Agent** | A configured entity that runs in sessions and processes work | Mayor, polecat, witness, etc. (hardcoded roles) |
| **Rig** | An external project directory registered in the city | Rig (same concept) |
| **Bead** | A durable work item (prompt/task) tracked in a backing store | Custom work items |
| **Formula** | A TOML workflow template defining multi-step DAGs | Plugin |
| **Order** | A periodic dispatch mechanism (cron-like) | Plugin |
| **Convoy** | A graph of related beads with parent-child relationships | Convoy |
| **Pack** | A shareable bundle of agent definitions, prompts, and formulas | N/A (new) |
| **Session** | A persistent chat conversation where an agent works | Session |
| **Controller** | The daemon that owns reconciliation, scaling, and health | Deacon watchdog |
| **Supervisor** | Machine-wide process managing city controllers | N/A (new) |

**The key shift:** In Gastown, behavior was encoded in role names and directory structure. In Gas City, agents are generic — roles emerge from prompts, formulas, orders, and configuration. The "gastown" pack provides familiar role names as conventions, not SDK law.

---

## Installation

Gas City is installed via Homebrew (already configured in your `homebrew.nix`):

```bash
brew install gastownhall/gascity/gascity
gc version
```

**Runtime dependencies** (you already have all of these):
- tmux, jq, git (nix)
- dolt (nix)
- bd / beads CLI (installed with gastown)
- flock (macOS built-in via coreutils)

**Upgrade:**
```bash
brew update && brew upgrade gascity
gc service restart
```

Or just run `rebuild` — your `homebrew.nix` has `onActivation.upgrade = true`.

---

## Your Setup

Your macDots configures Gas City with separate work/personal cities, mirroring your Gastown pattern:

```bash
# Aliases (from zsh.nix)
gc-work     # → gc --city ~/.gc-work   + work Claude config
gc-personal # → gc --city ~/.gc-personal + personal Claude config
gc          # → gc-work (default)
```

State directories:
- `~/.gc-work/` — work city
- `~/.gc-personal/` — personal city

The bare `gc` binary (without alias) uses cwd walk-up to discover the city — it traverses up from your current directory looking for a `city.toml`.

---

## Quickstart

### Create Your First City

```bash
# Initialize a work city from the tutorial template
gc-work init ~/.gc-work --template tutorial --provider claude
cd ~/.gc-work
gc-work start
```

The `--provider claude` flag configures Claude Code as the default agent provider.

### Add a Rig (Project)

```bash
# Register an existing repo
cd ~/repos/my-project
gc-work rig add .
```

This creates a `.beads/` database folder in the project and registers it in the city.

### Create and Route Work

```bash
# Create a bead (work item)
bd create "Fix the login timeout bug"
bd ready

# Route it to an agent
gc-work sling claude <bead-id>

# Or create + sling in one step
gc-work sling claude "Fix the login timeout bug"
```

### Watch an Agent Work

```bash
# Attach to the agent's session
gc-work session attach claude

# Or peek without attaching
gc-work session peek claude
```

---

## Configuration (city.toml)

The `city.toml` file is the single source of truth for a city. It replaces Gastown's scattered config across role directories.

### Top-Level Structure

```toml
[workspace]
name = "my-city"
default_provider = "claude"

# Provider definitions
[providers.claude]
display_name = "Claude Code"
command = "claude"
prompt_mode = "arg"
supports_hooks = true

[providers.codex]
display_name = "Codex"
command = "codex"
prompt_mode = "arg"

# Agent definitions
[[agent]]
name = "claude"
provider = "claude"
scope = "rig"
prompt_template = "prompts/claude.md"
idle_timeout = "30m"

# Rig registrations
[[rigs]]
name = "my-project"
path = "/Users/christopherstory/repos/my-project"
includes = ["packs/gastown"]

# Daemon settings
[daemon]
patrol_interval = "30s"
max_restarts = 5
restart_window = "1h"
shutdown_timeout = "5s"
```

### Key Sections

| Section | Purpose |
|---|---|
| `workspace` | City name, default provider |
| `providers` | Named provider presets (executables, flags, resume mechanisms) |
| `agent` | All configured agents (list of tables) |
| `rigs` | External project registrations |
| `packs` | Remote pack sources (git URLs) |
| `patches` | Post-merge modifications to agents/rigs/providers |
| `formulas` | Formula directory settings |
| `daemon` | Controller config (patrol, restarts, GC) |
| `orders` | Periodic dispatch settings |
| `api` | HTTP API server (default port 9443) |
| `beads/session/mail/events` | Backend provider selections |
| `agent_defaults` | City-wide defaults for all agents |

---

## Agents

Agents are the core workers. Unlike Gastown's hardcoded roles, agents are fully configurable.

### Agent Config Fields

```toml
[[agent]]
name = "worker"                      # unique identifier (required)
description = "General coding agent"
provider = "claude"                  # which provider to use
scope = "rig"                        # "rig" (per-project) or "city" (global)
dir = "workers"                      # identity prefix for rig-scoped agents
work_dir = "/tmp/sandbox"            # session working directory override
suspended = false                    # prevents spawning when true

# Session behavior
prompt_template = "prompts/worker.md"
nudge = "You have new work."         # text sent after startup
session = "acp"                      # transport override ("acp" or default tmux)
idle_timeout = "30m"                 # restart after this idle time
sleep_after_idle = "10m"             # suspend instead of restart

# Pool settings (for scaling)
max_active_sessions = 5
min_active_sessions = 1
drain_timeout = "5m"

# Lifecycle hooks
pre_start = "echo 'starting...'"
on_boot = "gc hook --inject"
on_death = "gc mail send --to mayor -m 'agent died'"

# Work routing
work_query = "bd list --state ready --limit 1"
sling_query = "bd list --state ready --label {{.Agent}}"
default_sling_formula = "standard-review"

# Session setup (runs after session creation)
session_setup = """
  cd {{.RigPath}}
  git pull --rebase
"""

# Dependencies
depends_on = ["mayor"]
```

### Agent Scopes

- **`scope = "rig"`** — One instance per registered rig (most agents)
- **`scope = "city"`** — One instance for the whole city (e.g., a mayor/coordinator)

### Wake Modes

- **`wake_mode = "resume"`** — Reattach to existing session (preserves context)
- **`wake_mode = "fresh"`** — Create new session (clean slate)

---

## Rigs

A rig is an external project directory. Think of it as "registering a repo with the city."

```bash
# Add a rig
gc rig add /path/to/project --name my-project

# List rigs
gc rig list

# Suspend/resume (skip in reconciliation)
gc rig suspend my-project
gc rig resume my-project

# Check health
gc rig status my-project

# Remove
gc rig remove my-project
```

### Rig Config in city.toml

```toml
[[rigs]]
name = "certifyos-api"
path = "/Users/christopherstory/repos/certifyos-api"
includes = ["packs/gastown"]           # packs to apply
max_active_sessions = 3
default_sling_target = "claude"

# Per-rig agent overrides (modify pack defaults without editing the pack)
[[rigs.overrides]]
agent = "polecat"
[rigs.overrides.pool]
max = 10

[[rigs.overrides]]
agent = "claude"
idle_timeout = "1h"
```

---

## Beads (Work Substrate)

Beads are the fundamental work unit — prompts/tasks tracked in a backing store (Dolt SQL database by default).

```bash
# Create a bead
bd create "Implement the user settings page"

# Mark it ready for routing
bd ready

# Show bead details
bd show <bead-id>

# List beads
bd list
bd list --state ready
bd list --label bug

# Route to an agent
gc sling claude <bead-id>

# Create + route in one step
gc sling claude "Implement the user settings page"

# Watch progress
gc sling claude <bead-id> --watch
```

### Bead States

created → ready → slung → closed

### Bead Metadata

Beads support labels, parent-child relationships, and arbitrary metadata. Used by formulas, convoys, and the controller for routing decisions.

---

## Formulas (Workflow Templates)

Formulas are TOML files defining multi-step workflow DAGs. They replace Gastown's plugins.

### Formula File Structure

```toml
# formulas/code-review.formula.toml
title = "Code Review"
description = "Review PR, run tests, approve or request changes"

[[steps]]
id = "review"
title = "Review the code changes"
description = "Read the diff, check for issues, write review comments"

[[steps]]
id = "test"
title = "Run the test suite"
description = "Execute all tests and report results"
needs = ["review"]

[[steps]]
id = "approve"
title = "Approve or request changes"
description = "Based on review and tests, approve the PR or request changes"
needs = ["review", "test"]
```

### Using Formulas

```bash
# List available formulas
gc formula list

# Preview a compiled formula
gc formula show code-review

# Instantiate into beads (cook)
gc formula cook code-review --var pr=123

# Route with formula
gc sling --formula code-review --var pr=123 claude
```

### Variables

Formulas support `{{key}}` substitution. Variables can be required (`required_vars`) and passed via `--var key=value`.

### Extends (Inheritance)

```toml
extends = "base-review"
# Adds or overrides steps from the parent formula
```

### Formula Resolution

Formulas are resolved from multiple layers (most specific wins):
1. Rig-local `formulas/` directory
2. City-level formula layers
3. Pack formulas

---

## Sessions

Sessions are persistent agent work environments, backed by tmux (default).

```bash
# Create a new session
gc session new claude --title "Feature work"

# Attach (interactive)
gc session attach claude

# Peek (read-only, no attach)
gc session peek claude --lines 50

# Send input without attaching
gc session nudge claude "Check the failing test"

# Suspend (free resources, keep state)
gc session suspend claude

# Wake (resume or fresh)
gc session wake claude

# View logs
gc session logs claude --follow

# Close permanently
gc session close claude

# Force kill (controller will restart)
gc session kill claude

# List all sessions
gc session list
gc session list --state running --json

# Prune old sessions
gc session prune --before "2026-03-01"

# Rename
gc session rename claude "Bug hunt session"
```

### Session Waits (Durable Dependencies)

```bash
# Register a wait (session blocks until satisfied)
gc session wait claude --on-beads "bead-123" --note "Waiting for data migration"

# List waits
gc wait list --session claude

# Mark a wait as satisfied
gc wait ready <wait-id>

# Cancel a wait
gc wait cancel <wait-id>
```

### Session Transports

| Transport | Use Case |
|---|---|
| tmux (default) | Local development, most common |
| ACP | Agent Client Protocol (structured communication) |
| Kubernetes | Containerized agents |
| subprocess | Lightweight, no tmux overhead |
| exec | Custom script-backed provider |

---

## Mail & Messaging

Inter-agent and human-to-agent messaging system.

```bash
# Send a message
gc mail send --to claude -s "Priority bug" -m "The auth endpoint is returning 500s"

# Send to all agents
gc mail send --all -s "Freeze notice" -m "No merges until release cut"

# Check inbox
gc mail inbox
gc mail count

# Read a message (marks as read)
gc mail read <mail-id>

# Peek without marking read
gc mail peek <mail-id>

# Reply
gc mail reply <mail-id> -m "Fixed in commit abc123"

# View thread
gc mail thread <mail-id>

# Archive (close without reading)
gc mail archive <mail-id>

# Mark read/unread
gc mail mark-read <mail-id>
gc mail mark-unread <mail-id>
```

### Handoffs

Transfer work context between agents:

```bash
gc handoff --target worker "Take over this PR review"
```

### Nudges (Deferred Reminders)

```bash
# Check nudge status
gc nudge status
```

---

## Orders (Periodic Dispatch)

Orders replace Gastown plugins. They run on schedules and can be exec orders (shell commands) or formula orders (instantiate workflows).

```bash
# List configured orders
gc order list

# Check which orders are due
gc order check

# Run an order manually
gc order run my-order

# View order details
gc order show my-order

# View execution history
gc order history my-order
```

Orders are configured in `city.toml`:

```toml
[orders]
skip = ["noisy-order"]    # orders to disable
max_timeout = "10m"       # hard cap on order execution time
```

---

## Packs (Shareable Config)

Packs are reusable bundles of agent definitions, prompts, scripts, and formulas.

### Pack Structure

```
my-pack/
  pack.toml           # metadata
  prompts/            # prompt templates
  scripts/            # lifecycle scripts
  formulas/           # workflow templates
```

### pack.toml

```toml
name = "my-team-pack"
schema = 1
version = "1.0.0"
requires_gc = ">=0.13.0"
city_agents = ["mayor"]    # these agents are city-scoped (not per-rig)
```

### Using Packs

**Local packs:**
```toml
[[rigs]]
name = "my-project"
path = "/path/to/project"
includes = ["packs/gastown", "packs/my-custom"]
```

**Remote packs (git):**
```toml
[[packs]]
url = "https://github.com/org/shared-pack.git"
ref = "main"
subdirectory = "packs/standard"
```

Fetch remote packs:
```bash
gc pack fetch
gc pack list
```

### Overriding Pack Defaults

Per-rig overrides let you customize pack agents without forking:

```toml
[[rigs.overrides]]
agent = "polecat"
provider = "codex"           # use Codex instead of Claude for polecats
idle_timeout = "1h"
[rigs.overrides.pool]
max = 5
```

---

## Supervision & Lifecycle

### Supervisor (Machine-Wide)

The supervisor manages city controllers across reboots.

```bash
# Install as system service (launchd on macOS)
gc supervisor install

# Start/stop
gc supervisor start
gc supervisor stop

# View status
gc supervisor status

# View logs
gc supervisor logs --follow

# Trigger reconciliation
gc supervisor reload

# Run in foreground (debugging)
gc supervisor run

# Uninstall
gc supervisor uninstall
```

### City Lifecycle

```bash
# Initialize
gc init ~/my-city --provider claude

# Start controller
gc start

# Stop (graceful)
gc stop

# Restart
gc restart

# Suspend (halt all agents, keep state)
gc suspend

# Resume
gc resume

# Register/unregister with supervisor
gc register
gc unregister

# List all supervisor-registered cities
gc cities
```

### Health & Diagnostics

```bash
# System overview
gc status
gc status --json

# Diagnostic checks (with optional auto-fix)
gc doctor
gc doctor --fix --verbose

# Event log
gc events
gc events --follow
gc events --type session --since "1h"

# Bead dependency graph
gc graph
gc graph --mermaid    # output as Mermaid diagram
gc graph --tree       # tree view

# Beads health check
gc beads health

# Service health
gc service doctor
gc service list
```

### Dashboard

```bash
gc dashboard serve --port 9443
# Opens web UI at http://localhost:9443
```

---

## CLI Reference

### Global Flags

| Flag | Purpose |
|---|---|
| `--city <path>` | Path to city directory (walks up from cwd if unset) |
| `--rig <name>` | Rig name or path (discovered from cwd if unset) |

### Command Categories

**Workspace:** `init`, `start`, `stop`, `restart`, `suspend`, `resume`, `register`, `unregister`, `cities`

**Agents:** `agent add/suspend/resume`, `session new/attach/close/kill/logs/peek/nudge/suspend/wake/wait/prune/rename`

**Work:** `sling`, `formula cook/list/show`, `converge create/approve/iterate/stop/status/list`, `convoy create/add/close/land/list/status/stranded`

**Communication:** `mail send/read/reply/inbox/archive/thread/count`, `handoff`, `nudge status`, `event emit`, `events`

**Configuration:** `config show/explain`, `rig add/remove/list/suspend/resume/status`, `pack fetch/list`, `skill`

**Infrastructure:** `supervisor install/start/stop/run/status/logs`, `service list/restart/doctor`, `order check/run/list/show/history`, `doctor`, `status`, `dashboard serve`

**Utilities:** `bd` (beads passthrough), `beads health`, `build-image`, `graph`, `hook`, `prime`, `runtime drain/drain-ack/drain-check/request-restart`, `wait cancel/inspect/list/ready`, `version`, `help`

---

## Coming from Gastown

### Concept Mapping

| Gastown | Gas City | Notes |
|---|---|---|
| Town | City | `gt` → `gc` |
| `gt install` | `gc init` | |
| `gt start/up` | `gc start` | |
| `gt down` | `gc stop` | |
| `gt sling` | `gc sling` | Direct mapping |
| `gt handoff` | `gc handoff` | Direct mapping |
| `gt convoy` | `gc convoy` | Direct mapping |
| `gt mail` | `gc mail` | Direct mapping |
| `gt agents` | `gc session` + `gc status` | |
| `gt session` | `gc session` | Direct mapping |
| `gt formula` | `gc sling --formula`, `gc order` | Split across commands |
| `gt gate/park` | `gc wait` | |
| `gt peek` | `gc session peek` | |
| `gt nudge` | `gc session nudge` | |
| `gt activity` | `gc event emit` + `gc events` | |
| `gt bead` | `bd` (direct) | |
| `gt config` | `gc config show/explain` | |
| `gt disable/enable` | `gc suspend/resume` | |
| Mayor, deacon, witness, etc. | Configured agents | No hardcoded roles |
| Plugin | Order or formula | |
| Dog | Usually exec order | No LLM session needed |
| Role directories | `city.toml` + packs | |
| `~/gt/...` directory tree | `~/.gc-work/` | Flat, config-driven |

### Key Mindset Changes

1. **No filesystem architecture** — Don't replicate Gastown's `~/gt/` tree. Use `dir` for scope and `work_dir` only when sessions need isolation.
2. **Controller owns infrastructure** — Reconciliation, scaling, health patrol belong in the controller, not in special roles.
3. **Agents are generic** — Roles come from prompts, formulas, and config, not from SDK types.
4. **Configuration first** — Most behavior lives in `city.toml` and packs, not code.
5. **Orders over agents for shell work** — If it doesn't need an LLM session, make it an exec order.

---

## Recommended City Configuration

### Work City (Claude-primary)

```bash
gc-work init ~/.gc-work --provider claude
gc-work start
gc-work supervisor install
```

Register your repos:
```bash
cd ~/repos/certifyos-api && gc-work rig add .
cd ~/repos/certifyos-web && gc-work rig add .
```

### Personal City (Cost-conscious)

```bash
gc-personal init ~/.gc-personal --provider claude
gc-personal start
```

When you get a bigger machine, you can configure local models as providers:
```toml
[providers.local]
display_name = "Ollama (local)"
command = "opencode"
env = { OPENCODE_MODEL = "ollama/qwen2.5-coder:14b" }
```

Then override specific agents to use local:
```toml
[[rigs.overrides]]
agent = "worker"
provider = "local"
```

### Quick Reference

| Task | Command |
|---|---|
| Start the city | `gc-work start` |
| Stop the city | `gc-work stop` |
| Add a project | `cd ~/repos/project && gc-work rig add .` |
| Create work | `gc-work sling claude "Do the thing"` |
| Watch agent | `gc-work session attach claude` |
| Peek at output | `gc-work session peek claude` |
| Send a message | `gc-work mail send --to claude -m "Check tests"` |
| City health | `gc-work status` |
| Diagnostics | `gc-work doctor` |
| View events | `gc-work events --follow` |
