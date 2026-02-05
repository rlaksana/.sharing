---
name: s2-openspec
description: Orchestrates OpenSpec workflow via skill invocations. Requires DRR from s1-quint or raw feature request.
disable-model-invocation: false
input: <feature_request_or_drr_id>
allowed-tools:
  - Bash
  - Edit
  - Read
  - Write
  - Grep
  - Glob
  - TodoWrite
  - SlashCommand
  - serena_find_symbol
  - serena_replace_symbol_body
  - serena_insert_after_symbol
  - serena_insert_before_symbol
---

# OpenSpec Workflow (Skill-Based)

> **Prerequisite:** Load `shared-core.md` for definitions (Execution Guardrails, AntiRot, Anti-Patterns).

**Input:** $ARGUMENTS

---

## Mode Detection & Preconditions

```
IF input matches DRR-ID pattern:
   → Verify DRR file exists in .quint/decisions/
   → IF DRR NOT FOUND:
        ERROR: "DRR not found. Run s1-quint first."
        TERMINATE skill
   → MODE = EXECUTION_ONLY (skip reasoning)

ELSE:
   → MODE = FULL (run reasoning + execution)
```

> **PRECONDITION (EXECUTION_ONLY mode):**
> DRR must exist — proof that user made Q5 decision via s1-quint.

---

## FULL MODE: Reasoning Kernel

> Run this ONLY if input is raw feature request.

### INIT
1. **Derive $INTENT** — What problem are we solving?
2. **Research (MANDATORY)** — Offline (ES/GrepAI/Serena) + Online (Docs)
3. **Bind $STDS** — Identify applicable patterns
4. **Set $BASE** — Define naive/obvious solution as benchmark

### DIVERGENCE
Generate 3+ hypotheses vs $BASE adhering to $STDS.

### GROUNDING
- Simulate execution
- Scan: vulnerabilities, edge cases, Surgical_Scope violations

### CONVERGENCE
Vote winner ($Alpha), prune weak logic.

### POLISH
Refine until FRICTION($Alpha, $STDS) == 0.

---

## OpenSpec Skills Reference

| Skill | Purpose |
|-------|---------|
| `/openspec-onboard` | Initialize OpenSpec in project |
| `/openspec-new-change <id>` | Start new change |
| `/openspec-ff-change` | Fast-forward artifacts |
| `/openspec-apply-change` | Implement per spec |
| `/openspec-verify-change` | Validate implementation |
| `/openspec-archive-change` | Archive completed change |
| `/openspec-continue-change` | Continue in-progress change |
| `/openspec-explore` | Explore codebase |
| `/openspec-sync-specs` | Sync specs with code |

---

## Workflow Steps

> **RULE:** Invoke skills, don't simulate.
> **FAILURE RULE:** If skill fails → STOP, FIX, RETRY. Do NOT proceed.

### Step 0: Pre-Check

If `openspec/` directory doesn't exist:
```
/openspec-onboard
```

### Step 1: Create Change

**Invoke:**
```
/openspec-new-change <change-id>
```

### Step 2: Generate Artifacts

**Invoke:**
```
/openspec-ff-change
```

### Step 3: Implement

**Invoke:**
```
/openspec-apply-change
```

This skill handles implementation based on generated specs.

### Step 4: Verify

**Invoke:**
```
/openspec-verify-change
```

If fails:
1. STOP — implementation is incomplete
2. FIX — address issues
3. RETRY — run verify again

**Change Audit:**
- `Audit-REQ`: Verify ALL DRR items are present
- `Audit-UNREQ`: Check `git diff`. If ANY line not in DRR → REVERT

### Step 5: Archive

**Invoke:**
```
/openspec-archive-change
```

---

## Flow Coverage

```mermaid
flowchart TD
    INPUT[Input] --> MODE{Mode?}
    MODE -->|DRR-ID| EXEC[EXECUTION_ONLY]
    MODE -->|Feature Request| FULL[FULL MODE]
    
    FULL --> REASON[Reasoning Kernel]
    REASON --> NEW[/openspec-new-change]
    NEW --> FF[/openspec-ff-change]
    FF --> APPLY
    
    EXEC --> CHECK{DRR exists?}
    CHECK -->|NO| ERROR[❌ Return to s1-quint]
    CHECK -->|YES| NEW
    
    APPLY[/openspec-apply-change] --> VERIFY[/openspec-verify-change]
    VERIFY -->|FAIL| FIX[Fix] --> VERIFY
    VERIFY -->|PASS| AUDIT[Change Audit]
    AUDIT -->|UNREQ found| REVERT[Revert] --> APPLY
    AUDIT -->|Clean| ARCHIVE[/openspec-archive-change]
    ARCHIVE --> DONE[✅ Complete]
```

---

## Failure Rules

| Condition | Action |
|-----------|--------|
| DRR not found (EXEC mode) | ERROR, terminate skill |
| `/openspec-onboard` fails | Check permissions, retry |
| `/openspec-new-change` fails | Check ID format, retry |
| `/openspec-ff-change` fails | Check spec syntax, retry |
| `/openspec-apply-change` fails | Check spec, retry |
| `/openspec-verify-change` fails | FIX implementation, retry |
| Audit-UNREQ finds changes | REVERT unrequested lines |
| `/openspec-archive-change` fails | Check verification passed first |

---

## Anti-Patterns (FORBIDDEN)

> See `shared-core.md` Anti-Patterns table.

---

## Output

```
✅ Change `<id>` implemented and archived.

Mode: FULL / EXECUTION_ONLY
Verification: PASSED
Guardrails: All checks passed
```
