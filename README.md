<div align="center">

# Hermes Smith

**Chat to build agents. Tasks route themselves.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Hermes%20Agent-blueviolet.svg)](https://hermes-agent.nousresearch.com)
[![Stars](https://img.shields.io/github/stars/zhuohoudeputao/hermes-smith?style=social)](https://github.com/zhuohoudeputao/hermes-smith)
[![Last Commit](https://img.shields.io/github/last-commit/zhuohoudeputao/hermes-smith)](https://github.com/zhuohoudeputao/hermes-smith/commits)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/zhuohoudeputao/hermes-smith/pulls)

A meta-agent profile for [Hermes Agent](https://hermes-agent.nousresearch.com) that builds agent profiles from conversation and routes Kanban tasks to the right agent — automatically.

</div>

---

## Why hermes-smith?

Building a new AI agent usually means: editing YAML configs, cherry-picking toolsets, writing personality files, installing skills, and manually assigning every task to the right agent. **Smith eliminates all of that.**

| Without Smith | With Smith |
|---|---|
| Hand-edit `config.yaml` for each agent | Describe what you want in chat — Smith builds it |
| Guess which tools/skills to enable | Smith proposes the right config and verifies it |
| Manually assign tasks to profiles | Tasks auto-route to the best-fit agent |
| Duplicate effort across similar agents | Smith remembers profiles and reuses them |

**Two modes, one agent:**

1. **Interactive Profile Builder** — Chat with Smith. It interviews you, designs the profile, creates it, configures model/tools/skills/personality, verifies it works, and tells you how to use it.

2. **Kanban Task Router** — When a task hits the board, Smith receives it first, analyzes the task type, checks existing profiles, and routes it to the best-fit agent — creating a new one only if no suitable profile exists.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    User creates task                     │
│              (hermes kanban create "…")                  │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │   Task assigned   │
              │    to smith       │
              │ (default_assignee)│
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  Smith analyzes   │
              │   task type       │
              └────────┬─────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  ROUTE   │ │  CREATE  │ │  HANDLE  │
    │ existing │ │   new    │ │  itself  │
    │ profile  │ │ profile  │ │ (meta)   │
    └────┬─────┘ └────┬─────┘ └────┬─────┘
         │            │            │
         ▼            ▼            ▼
    ┌────────────────────────────────────┐
    │  hermes kanban reassign TASK PROFILE│
    └──────────────────┬─────────────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  Dispatcher       │
              │  spawns worker    │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  Worker does the  │
              │  task, completes  │
              └──────────────────┘
```

## Quick Start

```bash
git clone https://github.com/zhuohoudeputao/hermes-smith.git
cd hermes-smith
bash install.sh
```

Then start chatting:

```bash
smith chat
> I need a research assistant that can search the web and remember things
```

The install script creates the `smith` profile (cloning your default), copies Smith's identity and skills, configures Kanban routing, and verifies everything.

## Requirements

- [Hermes Agent](https://hermes-agent.nousresearch.com) installed and configured
- A working LLM provider (OpenRouter, Anthropic, OpenAI, etc.)
- Hermes Kanban system (ships with Hermes — no extra install needed)

## Usage

### Interactive Mode — Build a Profile

```bash
smith chat
> I need a research assistant that can search the web and remember things

# Smith will:
# 1. Ask a few clarifying questions
# 2. Propose a design (name, model, tools, skills, personality)
# 3. Create and configure the profile
# 4. Verify it works
# 5. Tell you how to use it
```

### Task Router Mode — Kanban Routing

```bash
# Create a task — it goes to smith by default
hermes kanban create "Write a Python REST API" \
  --body "User management with FastAPI, include tests"

# Start the dispatcher (runs every 60s in the gateway)
hermes gateway start

# Or dispatch manually
hermes kanban dispatch

# Watch what happens
hermes kanban show TASK_ID
```

Smith will:
1. Receive the task (as default assignee)
2. Analyze the task type (coding, research, writing, etc.)
3. Check existing profiles in memory
4. Route to an existing profile or create a new one
5. Reassign the task and leave a comment explaining the routing decision
6. The dispatcher spawns the assigned profile to do the actual work

### Profile Types Smith Can Build

| Task type | Tools | Example focus |
|-----------|-------|---------------|
| Coding | terminal, file, code_execution | Clean code, test before done |
| Research | web, browser, memory, vision | Cite sources, structured output |
| Writing | web, file (no terminal) | Clarity, voice, audience-aware |
| Automation | terminal, cronjob | Safety-first, verify before applying |
| Data | terminal, file, code_execution, vision | Accuracy, visualization |
| DevOps | terminal, file | Infrastructure as code |

## Manual Install

If you prefer step-by-step:

```bash
# 1. Create the smith profile (clones config, .env, and skills from default)
hermes profile create smith --clone \
  --description "Meta-agent that builds and routes Hermes profiles"

# 2. Copy Smith's identity
cp smith/SOUL.md ~/.hermes/profiles/smith/SOUL.md

# 3. Copy the profile-smith skill
mkdir -p ~/.hermes/profiles/smith/skills/profile-smith/references
cp smith/skills/profile-smith/SKILL.md \
   ~/.hermes/profiles/smith/skills/profile-smith/SKILL.md
cp smith/skills/profile-smith/references/kanban-routing-details.md \
   ~/.hermes/profiles/smith/skills/profile-smith/references/

# 4. Configure Kanban routing
hermes config set kanban.default_assignee smith
hermes config set kanban.auto_decompose false
hermes -p smith config set kanban.default_assignee smith
hermes -p smith config set kanban.orchestrator_profile smith
hermes -p smith config set kanban.auto_decompose false

# 5. Verify
hermes -p smith chat -q "What are you?"
```

## How Smith Learns

Smith uses Hermes's persistent memory to remember which profiles it has created and what they're for. When a new task comes in:

1. Smith checks its memory for profiles matching the task type
2. If a match exists, it routes to that profile
3. If no match exists, it creates a new profile and saves a memory note

This means Smith gets better at routing over time — it won't create duplicate profiles, and it learns which profiles handle which tasks well.

## Repository Structure

```
hermes-smith/
├── smith/
│   ├── SOUL.md                              # Smith's identity (two modes)
│   ├── profile.yaml                         # Profile metadata
│   └── skills/
│       └── profile-smith/
│           ├── SKILL.md                     # Full workflow + routing logic
│           └── references/
│               └── kanban-routing-details.md # Command reference + test log
├── install.sh                               # Automated install script
├── README.md
├── LICENSE
└── .gitignore
```

## Configuration

Smith sets these Kanban config values (on both default and smith profiles):

```yaml
kanban:
  default_assignee: smith       # All new tasks go to smith first
  orchestrator_profile: smith   # Smith is the orchestrator
  auto_decompose: false         # Smith does routing, not the aux LLM
```

## Tested Workflow

The full routing flow was tested end-to-end:

1. Created a task: "Write a Python function that calculates Fibonacci numbers"
2. Smith received it, analyzed it as a trivial coding task
3. Smith checked existing profiles (only default and smith existed)
4. Smith decided to route to default (had terminal+file, sufficient for the task)
5. Smith left a comment explaining the routing decision
6. Task was reassigned to default
7. Default profile completed the task (created fibonacci.py, verified it)

See `smith/skills/profile-smith/references/kanban-routing-details.md` for the full test log.

## Uninstall

```bash
hermes profile delete smith
# Type 'smith' to confirm

# Optionally reset Kanban config
hermes config set kanban.default_assignee ''
hermes config set kanban.auto_decompose true
```

## Contributing

Pull requests welcome! If you have ideas for new routing strategies, profile templates, or improvements to the install flow, open an issue or PR.

## License

[MIT](LICENSE)
