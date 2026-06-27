# Kanban Task Routing — Command Reference and Tested Workflow

## Kanban Configuration

Set on both default and smith profiles:

```yaml
kanban:
  default_assignee: smith       # All new tasks go to smith first
  orchestrator_profile: smith   # Smith is the orchestrator
  auto_decompose: false         # Smith does routing, not the aux LLM
  dispatch_in_gateway: false    # Manual dispatch (or enable in gateway)
  dispatch_interval_seconds: 60 # Dispatcher tick interval
  failure_limit: 2              # Auto-block after 2 consecutive failures
```

To configure:
```bash
hermes config set kanban.default_assignee smith
hermes config set kanban.auto_decompose false
hermes -p smith config set kanban.default_assignee smith
hermes -p smith config set kanban.orchestrator_profile smith
hermes -p smith config set kanban.auto_decompose false
hermes -p smith config set kanban.dispatch_in_gateway false
```

## Key Commands for Routing

### Create a task (goes to smith by default)
```bash
hermes kanban create "Task title" --body "Description" --assignee smith
```

### Check task status
```bash
hermes kanban show TASK_ID          # Full details: status, assignee, events, comments
hermes kanban list                   # All tasks
hermes kanban list --assignee smith  # Tasks assigned to smith
hermes kanban list --status ready    # Tasks in ready state
```

### List known profiles (for routing decisions)
```bash
hermes profile list                  # All profiles
hermes kanban assignees              # Known profiles with task counts
hermes kanban assignees --json       # Machine-readable
```

### Reassign a task (the key routing action)
```bash
# --reclaim releases the current claim before reassigning
hermes kanban reassign TASK_ID PROFILE_NAME --reclaim --reason "Routing reason"
```

### Dispatch (spawn workers for ready tasks)
```bash
hermes kanban dispatch --dry-run     # Preview what would happen
hermes kanban dispatch               # Actually spawn workers
# Or start the gateway for automatic dispatch:
hermes gateway start                 # Dispatcher runs every 60s in gateway
```

### Complete a task (when Smith handles it itself)
```bash
hermes kanban complete TASK_ID --result "Done: description of what was done"
```

### Add a comment (for routing audit trail)
```bash
hermes kanban comment TASK_ID "Routing to PROFILE_NAME because..."
```

### View worker logs
```bash
hermes kanban log TASK_ID            # Worker output
hermes kanban tail TASK_ID           # Follow event stream
hermes kanban runs TASK_ID           # Attempt history
```

### Recover from issues
```bash
hermes kanban reclaim TASK_ID        # Release a stale/active claim
hermes kanban block TASK_ID "reason" # Mark blocked
hermes kanban unblock TASK_ID        # Return to ready
hermes kanban promote TASK_ID        # Force todo→ready
```

## End-to-End Test (2026-06-27)

### Setup
- Created `smith` profile via `hermes profile create smith --clone`
- Set kanban config: default_assignee=smith, auto_decompose=false
- Wrote SOUL.md with two modes (interactive builder + task router)
- Wrote profile-smith skill (v2.0.0) with full routing workflow

### Test: Fibonacci coding task
1. `hermes kanban create "Write a Python function that calculates Fibonacci numbers" --body "..." --assignee smith`
   → Task t_9cca6287 created, status=ready, assignee=smith

2. `hermes kanban dispatch`
   → Dispatcher spawned smith worker (PID 51876) in scratch workspace

3. Smith worker actions (from kanban log):
   - Loaded profile-smith skill via skill_view
   - Read task via kanban_show
   - Analyzed: "Coding (simple Python script), trivial complexity"
   - Ran `hermes profile list` → found only default and smith
   - Ran `hermes kanban assignees` → confirmed 2 profiles
   - Ran `hermes -p default config` → checked default's tools
   - ACCIDENTALLY ran `hermes -p default config set tools.enabled "['terminal', 'file', 'web']"` (confused inspect with modify)
   - Checked config damage, ran `hermes config check` → no errors
   - Decided: route to default (has terminal+file, sufficient for simple Python)
   - Left comment: "Routing to default profile. This is a simple Python coding task..."
   - Ran `hermes kanban reassign t_9cca6287 default --reclaim --reason "..."` → exit 130 (SIGINT)

4. Worker crashed (reclaim killed the process during reassign)
   - Task still assigned to smith, status=running
   - Manual reassign: `hermes kanban reassign t_9cca6287 default --reclaim --reason "..."` → success
   - Task now: status=ready, assignee=default

5. `hermes kanban dispatch`
   → Dispatcher spawned default worker

6. Default worker completed the task:
   - Created fibonacci.py (iterative, O(n) time, O(1) space)
   - Verified by running the script
   - Marked task done with summary

### Test Results
- Smith correctly analyzed and classified the task
- Smith correctly checked existing profiles before deciding
- Smith correctly decided to route (not create) since default was sufficient
- Smith left an audit-trail comment explaining the routing decision
- Two issues found: accidental config modification, reassign killed by reclaim
- Task was ultimately completed successfully by the routed profile

## Kanban Worker Environment

When the dispatcher spawns a worker, the worker sees:
- `HERMES_KANBAN_TASK=TASK_ID` — the task to work on
- `HERMES_KANBAN_BOARD=BOARD_SLUG` — the board
- `HERMES_PROFILE=PROFILE_NAME` — which profile to run as
- Kanban tools injected automatically (kanban_show, kanban_complete, kanban_comment, etc.)
- Working directory: scratch workspace (ephemeral) or worktree/dir (persistent)
- The worker's query is: "work kanban task TASK_ID"

The worker does NOT see:
- The main conversation context
- Memory from other profiles (unless memory is shared)
- The orchestrator's reasoning

This means Smith's routing decisions must be self-contained in the task comment and the reassign reason — the receiving worker won't know why it was chosen.
