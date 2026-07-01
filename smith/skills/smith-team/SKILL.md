---
name: smith-team
description: "Team management for Smith — fleet status, scaling, rebalancing, and analytics across all Hermes profiles."
version: 1.0.0
author: agent
metadata:
  hermes:
    tags: [hermes, profiles, team-management, fleet, analytics]
---

# Smith Team — Fleet Management

Manage your profile fleet as a team. See who's working, who's idle,
scale up busy profiles, and rebalance tasks.

## Commands

### Team Status

Show all profiles with their current workload:

```bash
# Full fleet overview
hermes profile list

# Task counts per assignee
hermes kanban assignees

# Combined view (run both, present in a table)
smith team status
```

Smith should present this as a table:

```
Profile     Gateway    Tasks (running/ready/total)  Model
─────────   ────────   ──────────────────────────   ─────
default     running    2/0/5                        glm-5.2
planner     stopped    0/0/0                        glm-5.2
coder       stopped    0/3/4                        glm-5.2
researcher  stopped    0/0/0                        glm-5.2
smith       running    0/0/1                        glm-5.2
```

### Scale Up

Create additional instances of a busy profile:

```bash
# Create coder-2, coder-3 with same config
for i in 2 3; do
  hermes profile create "coder-${i}" --clone-from coder \
    --description "Coding agent instance ${i}"
done
```

Use when:
- A profile has 3+ queued ready tasks
- Tasks are independent (no dependencies between them)
- The profile's model supports concurrent runs

### Scale Down

Retire idle profiles to save resources:

```bash
# Check if profile has any tasks first
hermes kanban list --assignee PROFILE --status ready,running,todo 2>/dev/null

# If empty, archive it
hermes profile delete NAME  # type NAME to confirm
```

Only retire when:
- Zero running/ready/todo tasks
- Profile hasn't been used in 7+ days
- Not the orchestrator or default profile

### Rebalance

Redistribute tasks across profiles:

```bash
# List ready tasks
hermes kanban list --status ready --json

# Reassign each to the best-fit profile
for task in $(hermes kanban list --status ready --json | jq -r '.[].id'); do
  # Analyze task, pick best profile, reassign
  hermes kanban show $task  # read title/body
  hermes kanban reassign $task BEST_PROFILE --reclaim --reason "Rebalanced to BEST_PROFILE"
done
```

### Analytics

Track profile productivity:

```bash
# Per-profile task history
hermes kanban list --assignee PROFILE --status done --json | \
  jq 'length'  # count completed

# Board-wide stats
hermes kanban stats

# Per-task timing
hermes kanban runs TASK_ID
```

Present as:

```
Profile     Done  Running  Queued  Success Rate
─────────   ────  ───────  ──────  ────────────
coder       12    1        3       92%
researcher  8     0        0       87%
writer      3     0        0       100%
```

## Decision Rules

1. **Scale up when**: profile has 3+ ready tasks AND tasks are independent
2. **Scale down when**: profile has 0 tasks for 7+ days AND is not orchestrator
3. **Rebalance when**: one profile has 3+ queued while another has 0 and matching skills
4. **Never scale the orchestrator** (smith/planner) — there should only be one
5. **Never delete default** — it's the fallback for all routing
6. **Check model costs** — scaling a $0.01/task profile to 3 instances is fine; scaling a $0.50/task profile needs user approval

## Integration with Templates

When scaling up, use the template if the profile was created from one:

```bash
# If coder was created from template:
smith create-from-template coder coder-2
# Instead of:
hermes profile create coder-2 --clone-from coder
```

This ensures the new instance has the same skills and SOUL.md, not just config.
