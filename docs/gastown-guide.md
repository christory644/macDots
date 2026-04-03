# Gastown Guide

A practical guide to running Gastown on macOS with tmux, tailored for a multi-repo workflow across two Claude accounts (work and personal).

## Table of Contents

- [Architecture at a Glance](#architecture-at-a-glance)
- [Your Setup](#your-setup)
- [Core Concepts](#core-concepts)
- [Getting Started](#getting-started)
- [Managing Rigs (Repos)](#managing-rigs-repos)
- [Tmux Integration](#tmux-integration)
- [Dispatching Work](#dispatching-work)
- [Monitoring and Tracking](#monitoring-and-tracking)
- [Multi-Repo Strategy for Work](#multi-repo-strategy-for-work)
- [Personal Projects Strategy](#personal-projects-strategy)
- [The Memory System](#the-memory-system)
- [Cost Tracking](#cost-tracking)
- [Maintenance](#maintenance)
- [Command Reference](#command-reference)

---

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────────┐
│  YOU (the Overseer)                                     │
│  ┌────────────────┐          ┌────────────────────┐     │
│  │  gt-work       │          │  gt-personal        │     │
│  │  ~/gt-work     │          │  ~/gt-personal      │     │
│  │  port 3307     │          │  port 3308          │     │
│  │  ~/.claude-work│          │  ~/.claude-personal │     │
│  └──────┬─────────┘          └──────┬──────────────┘     │
│         │                           │                    │
│    ┌────┴────┐                 ┌────┴────┐               │
│    │  Mayor  │                 │  Mayor  │               │
│    │ (coord) │                 │ (coord) │               │
│    └────┬────┘                 └────┬────┘               │
│    ┌────┴──────────────┐      ┌────┴────┐               │
│    │ Rig: auth-service │      │ Rig: ai │               │
│    │ Rig: web-app      │      │  -proj  │               │
│    │ Rig: shared-libs  │      └─────────┘               │
│    │ Rig: ...          │                                 │
│    └───────────────────┘                                 │
└─────────────────────────────────────────────────────────┘
```

A **town** is a workspace where a Mayor coordinates work across multiple **rigs** (repos). Each rig gets its own agents: a Witness (watches for problems), a Refinery (maintains code quality), and Polecats (workers that get spun up on demand to do actual tasks).

All of this runs in **tmux sessions** — every agent is a Claude Code instance running in its own tmux pane.

---

## Your Setup

You have two completely separate Gastown installations:

| | Work | Personal |
|---|---|---|
| **Town root** | `~/gt-work` | `~/gt-personal` |
| **Dolt port** | 3307 | 3308 |
| **Claude config** | `~/.claude-work` | `~/.claude-personal` |
| **Shell alias** | `gt` or `gt-work` | `gt-personal` |
| **Owner** | christopher.story@certifyos.com | christory@pm.me |

The aliases handle all routing automatically. Every `gt` command goes to your work town. Use `gt-personal` when working on side projects.

```bash
gt status              # work town status
gt-personal status     # personal town status
```

---

## Core Concepts

### The Cast of Characters

| Agent | Role | Tmux Session | One Per |
|---|---|---|---|
| **Mayor** | Coordinator. Routes work, handles escalations, manages cross-rig concerns. Your Chief of Staff. | `mayor` | Town |
| **Deacon** | Town-level watchdog. Runs patrols, health checks, audits. The Mayor's background process. | `deacon` | Town |
| **Witness** | Watches a rig. Reviews completed work, tracks failures, monitors polecats. | `<rig>-witness` | Rig |
| **Refinery** | Maintains code quality on main. Runs after merges, checks for regressions. | `<rig>-refinery` | Rig |
| **Polecat** | Worker. Spawned on demand, gets assigned an issue, works it, submits to merge queue, dissolves. | `<rig>-<name>` | Task |
| **Crew** | Persistent human-workspace clone within a rig. Your working directory alongside the agents. | `<rig>-crew-<name>` | Per person |

### The Work Pipeline

```
Issue (bead) → Sling to rig → Polecat spawns → Works the code → gt done
    → Merge queue → Witness reviews → Merged to main → Refinery checks
```

### Beads

A **bead** is a work item (issue, task, bug). Every bead has a prefixed ID like `auth-42` or `hq-7`. The prefix comes from the rig. Town-level beads use the `hq-` prefix.

### Convoys

A **convoy** groups related beads for tracking. "Ship the new auth flow" might be a convoy that tracks `auth-42`, `web-55`, and `shared-12` across three rigs. Convoys auto-close when all tracked beads complete.

### Molecules and Formulas

A **molecule** is an active workflow instance — a series of steps an agent follows. A **formula** is the template that creates molecules. Gastown ships with 47 built-in formulas for common workflows (code review, polecat work, releases, etc.).

### Hooks

Every agent has a **hook** — a slot for the one thing they're currently working on. Work on the hook survives session restarts, context compaction, and handoffs. When an agent restarts, its SessionStart hook runs `gt prime` which finds the hooked work and resumes.

---

## Getting Started

### 1. Start the daemon

The daemon is a lightweight Go process that heartbeats agents and processes lifecycle events:

```bash
gt daemon start           # work town
gt-personal daemon start  # personal town
```

To auto-start on login:

```bash
gt daemon enable-supervisor   # creates a launchd plist
```

### 2. Enable shell integration

```bash
gt enable
```

This sets `GT_TOWN_ROOT` and `GT_RIG` environment variables in your shell and wires up Claude Code SessionStart hooks so agents auto-prime on spawn.

### 3. Add your first rig

```bash
# Clone a repo into the work town
gt rig add auth-service git@github.com:certifyos/auth-service.git

# For large repos, use partial clone to save disk
gt rig add monorepo git@github.com:certifyos/monorepo.git --filter blob:none
```

### 4. Attach to the Mayor

```bash
gt mayor start    # spawn the Mayor session
gt mayor attach   # attach your terminal to it
```

Detach with `Ctrl+b d` (your tmux prefix + d, which for you is `Ctrl+a d`).

### 5. Verify

```bash
gt doctor -v       # full health check
gt status          # overview of all rigs and agents
gt rig list        # list registered rigs
```

---

## Managing Rigs (Repos)

### Adding rigs

```bash
# Standard clone
gt rig add <name> <git-url>

# Adopt a repo you already have cloned locally
gt rig add my-repo --adopt --url git@github.com:org/my-repo.git

# Partial clone (huge repos — downloads objects on demand)
gt rig add big-repo <url> --filter blob:none

# Custom beads prefix (default is derived from name)
gt rig add auth-service <url> --prefix auth

# Fork workflow (read from upstream, push to your fork)
gt rig add upstream-lib <upstream-url> --push-url <fork-url>
```

### Listing rigs

```bash
gt rig list
# Shows: name, state (OPERATIONAL/PARKED/DOCKED), witness, refinery, polecats, crew
```

### Parking and unparking (this is the key one)

**Park** is a lightweight pause. It stops the rig's Witness and Refinery agents, marks the rig as parked, and tells the daemon not to auto-restart them. The rig's data stays intact. Think of it as putting a repo on the shelf.

```bash
gt rig park auth-service      # stops witness + refinery, marks parked
gt rig unpark auth-service    # resumes agents, back to operational
```

**Dock** is a heavier pause. It stops everything (including polecats), persists the docked state via git so it syncs across machines, and is visible to all clones. Use this when a project is truly on ice.

```bash
gt rig dock old-service       # full shutdown, synced state
gt rig undock old-service     # bring it back
```

**When to use which:**

| Scenario | Use |
|---|---|
| Switching focus to another product group for the day | Park the idle rigs |
| Sprint ended, won't touch this repo for weeks | Dock it |
| Repo is archived / deprecated | `gt rig remove` |
| Just don't want polecats spawning but want monitoring | Park (witness stops too) — or just don't sling work to it |

### Booting and shutting down

```bash
gt rig boot auth-service      # start witness + refinery (not polecats)
gt rig shutdown auth-service   # stop all agents for this rig
gt rig restart auth-service    # shutdown + boot
```

### Removing rigs

```bash
gt rig remove old-service          # unregisters (does NOT delete files)
gt rig remove old-service --force  # kills running sessions first
```

---

## Tmux Integration

Gastown runs entirely inside tmux. Every agent is a Claude Code session in a tmux session. Here's how it maps:

### Session naming

```
gt-work-mayor           # Mayor
gt-work-deacon          # Deacon
auth-service-witness    # Witness for auth-service rig
auth-service-refinery   # Refinery for auth-service rig
auth-service-Maple      # Polecat named "Maple" working on auth-service
web-app-crew-chris      # Your crew workspace in web-app
```

(Polecat names are auto-generated from a namepool — they get names like Maple, Toast, Birch, etc.)

### Navigating sessions

Since your tmux prefix is `Ctrl+a`:

```
Ctrl+a s          # list all tmux sessions (built-in tmux)
Ctrl+a (          # previous session
Ctrl+a )          # next session
```

Or use Gastown's smart cycling:

```bash
gt cycle next     # next session in the same group
gt cycle prev     # previous session in the same group
gt town next      # switch to next town-level session (Mayor ↔ Deacon)
gt town prev      # switch to previous town-level session
```

### The feed window

The real-time activity feed can live in a dedicated tmux window:

```bash
gt feed --window   # opens a 'feed' window in the current tmux session
```

This gives you a TUI dashboard with:
- **Agent tree** (top): all agents organized by role with latest activity
- **Convoy panel** (middle): in-progress and recently landed convoys
- **Event stream** (bottom): scrollable chronological feed

Navigation: `j/k` scroll, `Tab` switch panels, `1/2/3` jump to panel, `p` toggle problems view, `q` quit.

### Attaching to agents

```bash
gt mayor attach          # attach to Mayor's tmux session

# For other agents, use tmux directly:
tmux attach -t auth-service-witness
tmux attach -t auth-service-Maple
```

### Practical tmux workflow

A typical work session might look like:

```bash
# 1. Start your day
gt daemon start
gt status                    # see what's running

# 2. Attach to Mayor for coordination
gt mayor attach              # Ctrl+a d to detach when done

# 3. Open the feed in a window
gt feed --window             # lives alongside your work

# 4. Work in your own terminal while agents work in theirs
# Use Ctrl+a s to jump between sessions when you want to peek

# 5. End of day
gt status                    # check what's still running
gt cleanup                   # kill orphaned processes
```

### sesh integration

Since you have sesh (smart tmux session manager), you can use it alongside Gastown:

```bash
sesh connect gt-work         # jump to your Gastown work sessions
```

The Gastown tmux sessions will show up in `sesh list` alongside your regular sessions.

---

## Dispatching Work

### Creating work items

```bash
# Create a bead (issue) directly
bd create "Fix the auth token refresh bug" --type bug --prefix auth

# Or assign to a crew member (creates bead + hooks it)
gt assign chris "Fix the auth token refresh bug" --rig auth-service
```

### Slinging work (the main dispatch command)

`gt sling` is THE command for getting work done. It hooks a bead to an agent and kicks off execution:

```bash
# Sling to a rig — auto-spawns a polecat
gt sling auth-42 auth-service

# Sling with natural language instructions
gt sling auth-42 auth-service --args "Focus on the JWT expiry edge case"

# Sling with merge strategy
gt sling auth-42 auth-service --merge=direct   # push straight to main
gt sling auth-42 auth-service --merge=mr       # merge queue (default)
gt sling auth-42 auth-service --merge=local    # keep on feature branch

# Batch sling — multiple beads, each gets its own polecat
gt sling auth-42 auth-43 auth-44 auth-service

# Sling with concurrency limit (be nice to Dolt)
gt sling auth-42 auth-43 auth-44 auth-service --max-concurrent 3

# Sling to Mayor for cross-rig coordination
gt sling hq-7 mayor

# Sling a formula (reusable workflow template)
gt sling mol-release mayor/

# Multi-line instructions via stdin
gt sling auth-42 auth-service --stdin <<'EOF'
Focus on:
1. JWT expiry edge case in refresh flow
2. Make sure the Redis cache invalidation works
3. Add integration tests
EOF
```

### Handoffs

When an agent runs out of context or you want a fresh start:

```bash
gt handoff                           # restart current session
gt handoff -s "Continue the auth fix" -m "Left off at the Redis integration"
gt handoff --collect                 # auto-collects current state into handoff
```

### The done signal

When a polecat finishes work:

```bash
gt done                              # submit to merge queue, signal completion
gt done --status ESCALATED           # hit a blocker, needs human help
gt done --status DEFERRED            # pausing, will come back
```

---

## Monitoring and Tracking

### Status overview

```bash
gt status              # town overview: rigs, agents, states
gt status --watch      # continuous refresh (every 2s)
gt status --fast       # skip mail lookups (faster)
```

### Activity trail

```bash
gt trail                     # recent commits from agents
gt trail commits --since 1h  # last hour's commits
gt trail beads               # recent work items
gt trail hooks               # recent hook activity
```

### Convoys (batch tracking)

```bash
# Create a convoy to track related work
gt convoy create "Ship new auth flow" --issues auth-42,web-55,shared-12

# Or let sling auto-create convoys (default behavior)
gt sling auth-42 auth-service    # auto-creates a convoy

# Check convoy status
gt convoy list                   # all convoys
gt convoy status hq-3            # specific convoy
gt convoy stranded               # convoys needing attention

# Interactive tree view
gt convoy --interactive
```

### Mountains (epics)

For large bodies of work with dependencies:

```bash
# Stage an epic (analyze dependencies, compute execution waves)
gt convoy stage hq-epic-auth

# Activate the Mountain-Eater (auto-dispatches work in waves)
gt mountain hq-epic-auth

# Monitor progress
gt mountain status hq-epic-auth
gt mountain pause hq-epic-auth   # pause if needed
gt mountain resume hq-epic-auth
```

### Changelogs

```bash
gt changelog              # this week's completed work
gt changelog --today      # today
gt changelog --rig auth   # specific rig
```

### Ready work

```bash
gt ready                  # all unblocked work across all rigs
gt ready --rig auth       # specific rig
```

### Web dashboard

```bash
gt dashboard --open       # opens browser to localhost:8080
gt dashboard --port 3000  # custom port
```

### Cost tracking

```bash
gt costs              # live session costs
gt costs --today      # today's spend
gt costs --week       # weekly spend
gt costs --by-rig     # breakdown by repo
gt costs --by-role    # breakdown by agent type
```

---

## Multi-Repo Strategy for Work

You have ~100 interconnected repos grouped by product. Here's how to structure that in Gastown without overwhelming the Mayor.

### The problem

If you register all 100 repos as rigs, the Mayor is tracking 100 Witnesses, 100 Refineries, and who knows how many Polecats. That's chaos. The Mayor's context window fills up with noise from repos you aren't actively touching.

### The solution: product-group rotation

**Only keep rigs operational for the product group you're actively working on.** Park everything else.

Say your repos are grouped roughly like:

```
auth/          → auth-service, auth-sdk, identity-provider
billing/       → billing-api, payment-gateway, invoice-service
platform/      → shared-libs, config-service, api-gateway
web/           → web-app, admin-portal, component-library
mobile/        → mobile-app, push-service
data/          → analytics-pipeline, data-warehouse, etl-jobs
```

### Step 1: Register the repos you work with most

Don't add all 100 at once. Start with one product group:

```bash
# Add the auth product group
gt rig add auth-service git@github.com:certifyos/auth-service.git --prefix auth
gt rig add auth-sdk git@github.com:certifyos/auth-sdk.git --prefix asdk
gt rig add identity-provider git@github.com:certifyos/identity-provider.git --prefix idp
```

### Step 2: Park when switching context

When you shift from auth work to billing work:

```bash
# Park the auth group
gt rig park auth-service
gt rig park auth-sdk
gt rig park identity-provider

# Unpark (or add) the billing group
gt rig unpark billing-api
gt rig unpark payment-gateway
```

### Step 3: Cross-product work with convoys

When a feature spans product groups, unpark the relevant rigs and create a convoy:

```bash
# Working on a feature that touches auth + billing + web
gt rig unpark auth-service
gt rig unpark billing-api
gt rig unpark web-app

# Create a convoy to track the cross-cutting work
gt convoy create "OAuth2 billing integration" \
  --issues auth-42,bill-17,web-55

# Or use mountains for larger epics with dependency ordering
gt mountain hq-epic-oauth-billing
```

### How many rigs should be operational at once?

A good rule of thumb: **3-8 operational rigs.** That's enough for the Mayor to track meaningfully without context window bloat. Park the rest.

The overhead per operational rig:
- 1 Witness tmux session (watching for problems)
- 1 Refinery tmux session (maintaining main)
- N Polecat sessions (spawned only when work is slung)
- Dolt database storage (lightweight)

Parked rigs have zero overhead — no sessions, no CPU, no context burden on the Mayor.

### Adding repos incrementally

You don't need to register all 100 repos on day one. Add them as you need them:

```bash
# Need to touch a repo you haven't registered yet?
gt rig add new-service git@github.com:certifyos/new-service.git

# Done with it for now?
gt rig park new-service

# Won't need it again for a long time?
gt rig dock new-service
```

### Shell helpers for product group management

You could add these to your zsh config if you find yourself switching groups often:

```bash
# Example: add to shellAliases in zsh.nix
gt-auth-up = "gt rig unpark auth-service && gt rig unpark auth-sdk && gt rig unpark identity-provider"
gt-auth-down = "gt rig park auth-service && gt rig park auth-sdk && gt rig park identity-provider"
```

Or use a more flexible approach — create beads for group management and let the Mayor handle it.

---

## Personal Projects Strategy

Your personal projects are mostly unrelated to each other. This is simpler.

### One rig per project

```bash
gt-personal rig add side-project git@github.com:christory644/side-project.git
gt-personal rig add another-thing git@github.com:christory644/another-thing.git
```

### Park what you're not touching

Since personal projects are disparate, you'll rarely need more than 1-2 rigs operational:

```bash
gt-personal rig park another-thing    # shelve it
gt-personal rig unpark side-project   # pick it back up
```

### Keep it lean

The personal town doesn't need the daemon running all the time. Start it when you're working on a side project, stop it when you're done:

```bash
gt-personal daemon start    # when you sit down to hack
gt-personal daemon stop     # when you're done
```

---

## The Memory System

Gastown has a persistent memory system that survives across sessions. Memories are injected when agents prime (start or restart).

```bash
# Store a memory
gt remember "Auth service uses RS256 JWTs, not HS256"
gt remember --type feedback "Don't mock the database in integration tests"
gt remember --type project "Billing migration deadline is 2026-04-30"
gt remember --type user "Senior Go developer, new to Rust"

# List memories
gt memories
gt memories --type feedback
gt memories auth           # search

# Remove a memory
gt forget auth-jwt-type
```

Memory types:
- **general** — default, anything useful
- **feedback** — behavioral corrections for agents
- **project** — project context and decisions
- **user** — information about collaborators
- **reference** — pointers to external resources

---

## Cost Tracking

Gastown tracks Claude API costs per session:

```bash
gt costs              # current live session costs
gt costs --today      # today's total
gt costs --week       # weekly total
gt costs --by-rig     # which repos are expensive
gt costs --by-role    # which agent types cost most (polecats usually dominate)
```

### Controlling costs

```bash
# Limit concurrent polecats (fewer parallel workers = lower burn rate)
gt config set scheduler.max_polecats 3

# Or use the scheduler for capacity-controlled dispatch
gt scheduler status
gt scheduler pause     # stop all new dispatches
gt scheduler resume    # resume
```

---

## Maintenance

### Daily

```bash
gt status              # quick health check
gt cleanup             # kill orphaned processes
```

### Weekly

```bash
gt doctor              # full diagnostic
gt doctor --fix        # auto-fix what it can
gt changelog --week    # review what got done
gt costs --week        # review spend
```

### After upgrading Gastown

```bash
brew upgrade gastown
gt upgrade             # run post-install migrations
gt doctor --fix        # fix anything the upgrade changed
```

### Pruning stale branches

```bash
gt prune-branches      # remove local tracking branches for completed polecats
```

### Talking to predecessor sessions

If you need to understand what a previous agent session was doing:

```bash
gt seance                          # list recent sessions
gt seance --role polecat           # filter by role
gt seance --talk <session-id>      # interactive conversation with predecessor
gt seance --talk <id> -p "What were you working on?"  # one-shot question
```

---

## Command Reference

### Essentials

| Command | What it does |
|---|---|
| `gt status` | Town overview |
| `gt rig list` | List all rigs with state |
| `gt rig add <name> <url>` | Register a new repo |
| `gt rig park <name>` | Pause a rig (lightweight) |
| `gt rig unpark <name>` | Resume a paused rig |
| `gt rig dock <name>` | Deep-freeze a rig (synced) |
| `gt rig undock <name>` | Thaw a docked rig |
| `gt sling <bead> <rig>` | Dispatch work |
| `gt done` | Signal work complete |
| `gt handoff` | Fresh session, keep work |
| `gt mayor attach` | Attach to Mayor session |
| `gt feed` | Real-time activity TUI |
| `gt ready` | Show unblocked work |
| `gt trail` | Recent activity |
| `gt doctor` | Health check |
| `gt cleanup` | Kill orphaned processes |

### Work management

| Command | What it does |
|---|---|
| `gt sling <bead> <target>` | THE dispatch command |
| `gt assign <crew> <title>` | Create + assign in one step |
| `gt hook` | Show/set current work |
| `gt unsling` | Remove work from hook |
| `gt done` | Submit to merge queue |
| `gt handoff` | End session, hand off |
| `gt convoy create` | Track related work |
| `gt convoy status <id>` | Check convoy progress |
| `gt mountain <id>` | Auto-grind an epic |
| `gt mq list` | View merge queue |
| `gt ready` | Unblocked work items |
| `gt changelog` | Completed work log |

### Agent management

| Command | What it does |
|---|---|
| `gt mayor start/stop/attach` | Mayor lifecycle |
| `gt daemon start/stop/status` | Daemon lifecycle |
| `gt rig boot/shutdown <name>` | Start/stop rig agents |
| `gt cycle next/prev` | Switch between related sessions |
| `gt town next/prev` | Switch town-level sessions |
| `gt cleanup` | Kill orphaned Claude processes |

### Diagnostics

| Command | What it does |
|---|---|
| `gt doctor [-v] [--fix]` | Full health check |
| `gt vitals` | Health dashboard |
| `gt costs [--today/--week]` | Cost tracking |
| `gt metrics` | Command usage stats |
| `gt trail` | Recent commits/beads/hooks |
| `gt feed` | Real-time activity TUI |
| `gt seance` | Talk to predecessor sessions |
| `gt whoami` | Current identity |
| `gt info` | Version and what's new |

### Configuration

| Command | What it does |
|---|---|
| `gt config agent list` | List agent configs |
| `gt config set <key> <val>` | Set config value |
| `gt rig config show <rig>` | Rig-specific config |
| `gt rig settings show <rig>` | Rig behavioral settings |
| `gt remember <text>` | Store persistent memory |
| `gt memories` | List memories |
| `gt forget <key>` | Remove a memory |
| `gt formula list` | Available workflow templates |
| `gt scheduler status` | Dispatch scheduler state |
