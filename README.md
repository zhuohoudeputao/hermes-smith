# Hermes Smith

A meta-agent profile for [Hermes Agent](https://hermes-agent.nousresearch.com) that builds and routes agents from conversation.

Smith has two modes:

1. **Interactive Profile Builder** — Chat with Smith to describe what kind of agent you need. It interviews you, designs the profile, creates it, configures it (model, tools, skills, personality), verifies it, and hands it off.

2. **Kanban Task Router** — When a Kanban task is created, Smith receives it first (as the default assignee), analyzes the task type, checks existing profiles, and routes the task to the best-fit agent — creating a new one if no suitable profile exists.

The core idea: instead of manually editing config files and installing skills for each new agent, you chat with Smith and it builds agents for you. And instead of manually assigning Kanban tasks to specific profiles, Smith acts as an intelligent router that learns which profiles handle which tasks.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    User creates task                     │
│              (hermes kanban create "...")                │
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

## Requirements

- [Hermes Agent](https://hermes-agent.nousresearch.com) installed and configured
- A working LLM provider (OpenRouter, Anthropic, OpenAI, etc.)
- Hermes Kanban system (ships with Hermes, no extra install needed)

## Quick Install

```bash
git clone https://github.com/zhuohoudeputao/hermes-smith.git
cd hermes-smith
bash install.sh
```

The install script:
1. Creates the `smith` profile by cloning your default profile
2. Copies Smith's SOUL.md and the profile-smith skill into the new profile
3. Configures Kanban routing (smith as default assignee, auto_decompose off)
4. Verifies the installation

After install, start chatting with Smith:

```bash
smith chat
```

## Manual Install

If you prefer to do it step by step:

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

### Common Profile Types Smith Can Build

| Task type | Tools | Example SOUL.md focus |
|-----------|-------|----------------------|
| Coding | terminal, file, code_execution | Clean code, test before done |
| Research | web, browser, memory, vision | Cite sources, structured output |
| Writing | web, file (no terminal) | Clarity, voice, audience-aware |
| Automation | terminal, cronjob | Safety-first, verify before applying |
| Data | terminal, file, code_execution, vision | Accuracy, visualization |
| DevOps | terminal, file | Infrastructure as code |

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

To change them after install:

```bash
hermes config set kanban.default_assignee smith
hermes config set kanban.auto_decompose false
hermes -p smith config set kanban.default_assignee smith
hermes -p smith config set kanban.orchestrator_profile smith
hermes -p smith config set kanban.auto_decompose false
```

## How Smith Learns

Smith uses Hermes's persistent memory to remember which profiles it has created and what they're for. When a new task comes in:

1. Smith checks its memory for profiles matching the task type
2. If a match exists, it routes to that profile
3. If no match exists, it creates a new profile and saves a memory note

This means Smith gets better at routing over time — it won't create duplicate profiles, and it learns which profiles handle which tasks well.

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

## License

MIT
