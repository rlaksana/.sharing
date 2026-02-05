---
name: s2-openspec
description: Orchestrates OpenSpec workflow. Emits /opsx:* commands. Requires DRR from s1-quint.
disable-model-invocation: false
input: <drr-id>
allowed-tools:
  - SlashCommand
  - Read
  - Glob
---

# S2-OpenSpec: Orchestrator

> **Role:** Planner that decides which `/opsx:*` command to emit next.
> **Executor:** OpenSpec commands (`/opsx:*`) handle actual state/artifact changes.

**Input:** $ARGUMENTS (DRR-ID from s1-quint)

---

## Preconditions

```
1. Verify DRR exists in .quint/decisions/
   → IF NOT FOUND: ERROR "No DRR. Run s1-quint first." TERMINATE

2. Check if openspec/ folder exists
   → IF NOT: Emit /opsx:onboard first
```

---

## OPSX Commands Reference

> Commands live in project's `.claude/commands/opsx/` folder.
> Invoke as `/opsx:<command>`.

| Command | Purpose |
|---------|---------|
| `/opsx:onboard` | Initialize OpenSpec in project |
| `/opsx:new` | Start new change |
| `/opsx:ff` | Fast-forward artifacts |
| `/opsx:continue` | Continue in-progress change |
| `/opsx:apply` | Implement per spec |
| `/opsx:verify` | Validate implementation |
| `/opsx:archive` | Archive completed change |
| `/opsx:bulk-archive` | Archive multiple changes |
| `/opsx:sync` | Sync specs with code |
| `/opsx:explore` | Explore codebase |

---

## Decision Logic (All Scenarios)

| Scenario | Condition | Emit Command |
|----------|-----------|--------------|
| First-time setup | No `openspec/` folder | `/opsx:onboard` |
| New change | No active change | `/opsx:new <drr-id>` |
| Resume work | Active change exists | `/opsx:continue` |
| Generate artifacts | After new/continue | `/opsx:ff` |
| Implement | Plan complete | `/opsx:apply` |
| Validate | Implementation done | `/opsx:verify` |
| Complete single | Verification passed | `/opsx:archive` |
| Complete multiple | Multiple changes done | `/opsx:bulk-archive` |
| Sync existing code | Code changed outside spec | `/opsx:sync` |
| Research codebase | Need understanding first | `/opsx:explore` |

---

## Workflow Scenarios

### Scenario A: Happy Path (New Change)

```
/opsx:onboard   ← if first time
/opsx:new <id>
/opsx:ff
/opsx:apply
/opsx:verify
/opsx:archive
```

### Scenario B: Resume In-Progress Change

```
/opsx:continue
/opsx:ff        ← if artifacts incomplete
/opsx:apply
/opsx:verify
/opsx:archive
```

### Scenario C: Multiple Changes

```
/opsx:new <id1>
/opsx:ff → /opsx:apply → /opsx:verify
/opsx:new <id2>
/opsx:ff → /opsx:apply → /opsx:verify
/opsx:bulk-archive
```

### Scenario D: Sync After External Changes

```
/opsx:sync      ← updates specs from code
/opsx:verify
/opsx:archive
```

### Scenario E: Research Before Planning

```
/opsx:explore   ← understand codebase
/opsx:new <id>
... continue normal flow
```

---

## Flow (All Paths)

```mermaid
flowchart TD
    START[DRR from s1] --> INIT{openspec/ exists?}
    INIT -->|NO| ONBOARD[/opsx:onboard]
    INIT -->|YES| CHECK
    ONBOARD --> CHECK{Active change?}
    
    CHECK -->|NO| NEW[/opsx:new]
    CHECK -->|YES| CONTINUE[/opsx:continue]
    CHECK -->|EXPLORE| EXPLORE[/opsx:explore] --> NEW
    
    NEW --> FF[/opsx:ff]
    CONTINUE --> FF
    
    FF --> APPLY[/opsx:apply]
    APPLY --> VERIFY[/opsx:verify]
    
    VERIFY -->|FAIL| FIX[Fix] --> VERIFY
    VERIFY -->|PASS| ARCHIVE{Multiple changes?}
    
    ARCHIVE -->|NO| SINGLE[/opsx:archive]
    ARCHIVE -->|YES| BULK[/opsx:bulk-archive]
    
    SINGLE --> DONE[✅ Complete]
    BULK --> DONE
    
    SYNC[/opsx:sync] --> VERIFY
```

---

## Failure Rules (All Commands)

| Command | Failure Condition | Action |
|---------|-------------------|--------|
| `/opsx:onboard` | Permission denied | Check folder permissions, retry |
| `/opsx:new` | Invalid ID / already exists | Check ID format, use continue |
| `/opsx:ff` | Spec syntax error | Fix spec, retry |
| `/opsx:continue` | No active change | Use new instead |
| `/opsx:apply` | Spec incomplete | Run ff first |
| `/opsx:verify` | Tests fail | FIX code, retry |
| `/opsx:archive` | Verify not passed | Run verify first |
| `/opsx:bulk-archive` | Some changes incomplete | Complete individual changes |
| `/opsx:sync` | Conflict detected | Resolve conflicts manually |
| `/opsx:explore` | No codebase | Run onboard first |

---

## Output

```
✅ Change <id> implemented and archived via OpenSpec.
Commands executed: [list of /opsx:* commands used]
```
