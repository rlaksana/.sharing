---
name: s2-openspec
description: Orchestrates OpenSpec OPSX workflow with conditional Logic Kernel reasoning.
disable-model-invocation: false
input: <feature_request_or_drr>
allowed-tools:
  - Bash
  - Edit
  - Read
  - Write
  - Grep
  - Glob
  - TodoWrite
  - serena_find_symbol
  - serena_replace_symbol_body
  - serena_insert_after_symbol
  - serena_insert_before_symbol

---

# OpenSpec OPSX Workflow Orchestrator

> **Prerequisite:** Load `shared-core.md` for definitions (Execution Guardrails, AntiRot, Anti-Patterns).

**Input:** $ARGUMENTS

**System:** Windows + PowerShell (`pwsh`) for all Bash commands.

---

## Mode Detection

```
IF input matches DRR-ID pattern (from s1-quint):
   → MODE = EXECUTION_ONLY (skip reasoning)

ELSE:
   → MODE = FULL (run reasoning + execution)
```

---

## FULL MODE: Reasoning Kernel

> Run this ONLY if input is raw feature request.

### INIT
1. **Derive $INTENT** — What problem are we solving?
2. **Research (MANDATORY)** — Offline (ES/GrepAI/Serena) + Online (Docs) to prevent hallucination.
   - *Exception:* Skip ONLY if Handoff from S1 (context already vetted).
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

## Execution Guardrails

> Apply all guardrails from `shared-core.md`: Think Before Coding, Simplicity First, Surgical Changes, AntiRot, Goal-Driven Execution.

---

## OpenSpec Workflow

### Commands

| Command | Purpose |
|---------|---------|
| `/opsx:new <name>` | Start new change |
| `/opsx:ff <name>` | Fast-forward all artifacts |
| `/opsx:apply <name>` | Implement tasks |
| `/opsx:verify <name>` | Validate implementation |
| `/opsx:archive` | Archive completed change |

### CLI (via Bash)

```powershell
openspec init                           # Initialize
openspec update                         # Update files
openspec list --json                    # List changes
openspec validate "<id>" --strict --json
```

---

## Workflow Steps

> **RULE:** You cannot mark a step complete unless the corresponding slash command or script has been executed.
> **RULE:** Do not "simulate" steps. Run the commands.
> **FAILURE RULE:** If a command fails (red text/error code):
> 1.  **STOP IMMEDIATELY**.
> 2.  **ANTI-FALLBACK:** You are STILL in the protocol.
>     - **DO NOT** abandon the command to "just edit the files manually".
>     - **DO NOT** proceed to the next step.
> 3.  **FIX** the error (read logs, debug).
> 4.  **RETRY** the command.

### Step 0: Pre-Check
```powershell
if (-not (Test-Path "openspec")) { openspec init }
openspec update
```

### Step 1: Create Change
`/opsx:new <change-id>`

### Step 2: Create Artifacts
`/opsx:ff <change-id>` or `/opsx:continue`

### Step 3: Implement
`/opsx:apply <change-id>`

### Step 4: Test
```powershell
if (Test-Path "package.json") { npm test }
if (Test-Path "pyproject.toml") { pytest }
if (Test-Path "*.csproj") { dotnet test }
```

### Step 5: Verify
1. `/opsx:verify <change-id>` (MUST PASS)
   - If verify fails:
     1.  **STOP**. Implementation is incomplete/broken.
     2.  **FIX** the issues.
     3.  **RETRY** `/opsx:verify`.
     4.  **REPEAT** until PASS.
2. **Change Audit:**
   - `Audit-REQ` (Traceability): Verify ALL DRR items are present.
   - `Audit-UNREQ` (Anti-Rot): Check `git diff`. If ANY line exists that is not in DRR -> REVERT.

### Step 6: Archive
`/opsx:archive`

---

## Anti-Patterns (FORBIDDEN)

> See `shared-core.md` Anti-Patterns table.

---

## Output

```
✅ Change `<id>` implemented and archived.

Mode: FULL / EXECUTION_ONLY
Tests: PASSED
Verification: PASSED
Guardrails: All checks passed
```
