---
name: s2-openspec
description: Sequential execution workflow for OpenSpec (FF/Apply/Verify/Archive) via /opsx slash commands. Executes steps inline without user interaction.
disable-model-invocation: false
input: <drr-id>
allowed-tools:
  - SlashCommand
  - Read
  - Glob
  - Task
  - Bash
---

# S2-OpenSpec: Sequential Execution Workflow

> **Role:** Execute the steps below **inline, one by one**, in your current turn. This is NOT a background process.
> **Logic:** Handle all scenarios (Success, Fail, Retry, Pivot) using project capabilities.
> **Mandate:** Execute each step sequentially without asking the user for permission, review, or confirmation. When a step finishes, IMMEDIATELY execute the next step. Stopping to ask "Should I continue?" or "Would you like to review?" is a FATAL ERROR.
> **Constraint:** MUST ingest DRR Constraints Bundle and propagate to all artifacts.

> 🚨 **ANTI-HALLUCINATION RULE:**
> This skill is a **checklist of steps to execute**, not a daemon or service.
> - Do NOT announce "state machine is now active" or "autonomous execution in progress"
> - Do NOT output a summary table of all states before starting
> - Do NOT describe what you WILL do — just START DOING IT from STATE 0
> - Your FIRST action must be a concrete tool call (reading DRR, running a command), not prose

**Input:** $ARGUMENTS

> ⛔ **INPUT GUARDRAIL:**
> Verify `$ARGUMENTS` is a specific DRR-ID (e.g., `drr-0123...`).
> If input is a generic instruction like "Implement this", **REJECT** and tell user to use `/s1-quint` first.

---

## Pre-Flight: Name Normalization

**CRITICAL:** DRR-ID input MUST be normalized to lowercase kebab-case before use.

**Action:** Before any state execution, normalize the input name:
```bash
node ~/.claude/skills/s2-openspec/scripts/normalize-change-name.js "$ARGUMENTS"
```

**Purpose:**
- Converts "DRR-2026-02-13-test" → "drr-2026-02-13-test"
- Prevents kebab-case validation errors on uppercase prefixes
- Ensures consistent naming across all OpenSpec operations

**All subsequent `$ARGUMENTS` references in this skill use the normalized name.**

---

## Pre-Flight: DRR Ingestion

**MANDATORY:** Before any state execution, read the DRR and extract:

1. **Constraints Bundle** (propagate to all artifacts)
2. **Verification Evidence Required** (enforce canonical paths)
3. **Assumption Ledger** (respect WAIVER items)

If DRR missing Constraints Bundle → **TERMINATE.** Output: "❌ S2 TERMINATED: DRR missing Constraints Bundle. S1 failed to produce valid DRR."
If DRR missing Verification Evidence Required → **TERMINATE.** Output: "❌ S2 TERMINATED: DRR missing Verification Evidence. S1 failed to produce valid DRR."

---

## Execution Logging (R6 Integrity)

> **MANDATE:** Log all state transitions for S3-Audit R6 verification.

**Setup:**
```javascript
const { ExecutionLogger } = require('.quint/utils/execution-logger');
const log = new ExecutionLogger($ARGUMENTS);  // Use DRR ID as log scope
```

**State Logging Pattern:**
- **At state start:** `log.startPhase('S{n}', 's2-openspec', { context })`
- **At state end:** `log.endPhase('S{n}', 'COMPLETE'|'ERROR', { metadata })`

**Log Output:** `.quint/execution/$ARGUMENTS/execution.jsonl`

---

## Execution Steps

**Thinking Process:** Before every step, identify your current state and condition. Execute the action. Do not ask for permission. Do not announce what you will do — just do it.

### STATE 0: PRE-FLIGHT CHECK

> **LOG:** `log.startPhase('S0', 's2-openspec', { drr_id: $ARGUMENTS })`

**Check:** Is OpenSpec CLI initialized in this project?
- **Check:** Check if `openspec/` directory exists in project root
- **NO (Scn P1):** OpenSpec not initialized
  - **Action:** Run `openspec init --tools claude --force` to auto-initialize
  - **Proceed:** To [STATE 1]
- **YES:** OpenSpec already initialized
  - **Proceed:** To [STATE 1]

> **Note:** OpenSpec init creates `openspec/` folder. The `openspec status --json` returning "No changes found" means initialized but no changes exist - this is OK, not an error.

### STATE 1: CHANGE SETUP → ARTIFACT GENERATION (MERGED)

> **LOG:** `log.startPhase('S1', 's2-openspec')`

**Action:** Invoke `/opsx:ff $ARGUMENTS` directly.

**Rationale:** `/opsx:ff` handles both change creation (if not exists) AND artifact generation in one flow. This bypasses the STOP point in `/opsx:new` and achieves full autonomy.

- **Trigger:** Invoke `/opsx:ff $ARGUMENTS`.
- **Context:** Use `context: same_task`.
- **Handling Pauses:** If `/opsx:ff` pauses to ask a question (e.g., "What change do you want to work on?"), DO NOT stop to ask the user. Autonomously answer the question using the context from the DRR constraints.
- **Proceed:** To [STATE 2]

### STATE 2: IMPLEMENTATION (APPLY)

> **LOG:** `log.startPhase('S2', 's2-openspec')`

**Action:** Invoke `/opsx:apply $ARGUMENTS`.
- **Handling Pauses:** If `/opsx:apply` pauses because tasks are ambiguous or an issue is encountered, DO NOT ask the user. Analyze the artifacts yourself, make a technical decision, continue the tasks, and document your resolution.
- **Result Analysis:**
  - **Success:** Proceed to [STATE 3] (Verification).
  - **Fail "Incomplete" (Scn A1):** **Retry.** Rerun `/opsx:ff`.
  - **Fail "Looping" (Scn A2):** After 2 retries, **TERMINATE.** Output: "❌ S2 TERMINATED: Apply looping after 2 retries. Implementation blocked."

> **IMPORTANT:** `/opsx:ff` adalah **skill-level workflow**, bukan CLI command.
> FF menjalankan sequence: `openspec new change` → `openspec status` → `openspec instructions` → create artifacts.
> Ini adalah abstraction layer di atas OpenSpec CLI, bukan direct command mapping.

**Verification Task Template (Injected into tasks.md):**

```markdown
## Verification Tasks

### V1: Unit Tests
- **Task:** Implement unit tests per Test Contract
- **Evidence:** `openspec/changes/$ARGUMENTS/evidence/unit-tests.log`
- **Pass Criteria:** All tests PASS, coverage >= 80%

### V2: Integration Tests
- **Task:** Implement integration tests per Test Contract
- **Evidence:** `openspec/changes/$ARGUMENTS/evidence/integration-tests.log`
- **Pass Criteria:** All tests PASS

### V3: Coverage Verification
- **Task:** Generate coverage report
- **Evidence:** `openspec/changes/$ARGUMENTS/evidence/coverage.json`
- **Pass Criteria:** Line coverage >= 80%, Branch coverage >= 70%

### V4: Constraint Validation
- **Task:** Verify all DRR constraints are satisfied
- **Evidence:** `openspec/changes/$ARGUMENTS/evidence/constraint-check.md`
- **Pass Criteria:** All C-* constraints verified with evidence
```

### STATE 4: (RESERVED FOR FUTURE USE)

> **Note:** STATE 4 is reserved for future extensibility. Current workflow jumps STATE 3 → STATE 5 directly.

### STATE 3: VERIFICATION & RETRY LOOP

> **LOG:** `log.startPhase('S3', 's2-openspec')`

**Action:** Verify the implementation and generate evidence files.
- **Trigger:** Invoke `/opsx:verify $ARGUMENTS`.
- **Handling Pauses:** If `/opsx:verify` asks to select a change due to ambiguity, DO NOT prompt the user. You must select the change matching `$ARGUMENTS` automatically.
- **Evidence Generation:** After verify, MUST create:
  - `openspec/changes/$ARGUMENTS/verify.log` — Complete verification output
  - `openspec/changes/$ARGUMENTS/verification_result.json` — Structured result

**verification_result.json format:**
```json
{
  "drr_id": "$ARGUMENTS",
  "timestamp": "<ISO_8601>",
  "status": "PASS|FAIL",
  "tests": {
    "unit": { "passed": <n>, "failed": <n>, "status": "PASS|FAIL" },
    "integration": { "passed": <n>, "failed": <n>, "status": "PASS|FAIL" }
  },
  "coverage": { "lines": <pct>, "branches": <pct> },
  "constraints_verified": [
    { "id": "C-F1", "status": "PASS|FAIL", "evidence": "..." }
  ]
}
```

- **Result Analysis:**
  - **PASS (Scn V1):** **Auto-Simplify.** Proceed to [STATE 5].
    - Note: If incomplete manual tasks exist, log: "⚠️ X task(s) incomplete - requires manual verification"
  - **PASS with Incomplete (Scn V1b):** If tasks incomplete but implementation correct:
    - Log: "⚠️ X task(s) incomplete - marking PASS with caveats"
    - Add `"incomplete_tasks": ["task description"]` to verification_result.json
    - Proceed to [STATE 5].
  - **FAIL < 3 Times (Scn V2):**
    - **Auto-Fix:** Invoke `/opsx:apply $ARGUMENTS` again.
    - **Context:** "Fix the failing tests found in verification."
    - **Loop:** Return to [STATE 3] (Verification) after applying fixes.
  - **FAIL >= 3 Times (Scn V3):**
    - **TERMINATE.** Output: "❌ S2 TERMINATED: Verification failed 3 times. Cannot auto-fix."

### STATE 5: CODE SIMPLIFICATION

> **LOG:** `log.startPhase('S5', 's2-openspec')`

**Action:** Refactor for clarity and maintainability.
- **Pre-Check:** Attempt to invoke `Task` tool with `subagent_type="code-simplifier"`.
- **Log:** "Attempting code simplification..."
- **Context:** "Simplify and refine code from the recently completed implementation. Focus on: removing redundancy, improving naming, reducing nesting, extracting meaningful functions, and enhancing readability. Preserve ALL verified behavior."
- **Result Analysis:**
  - **Success (Scn S1):** Log: "Code simplification complete." Proceed to [STATE 6].
  - **No Changes Needed (Scn S2):** Log: "No simplification needed." Proceed to [STATE 6].
  - **Subagent Unavailable (Scn S3):** Log: "⚠️ Code-simplifier plugin not available. Skipping refactoring step." Proceed to [STATE 6].
  - **Fail/Critical Error (Scn S4):** Log: "⚠️ Code simplification failed. Skipping." Proceed to [STATE 6].
- **Mandate:** This step runs automatically post-verification. Gracefully skip if plugin unavailable.
- **Note for Sharing:** This step requires the `code-simplifier` plugin. If unavailable, workflow continues without refactoring.

### STATE 6: ARCHIVE (GATED)

> **LOG:** `log.startPhase('S6', 's2-openspec')`

> ⛔ **ARCHIVE GATE:** Archive is **BLOCKED** unless verification_result.json exists with `"status": "PASS"`.

**Pre-Archive Check:**
1. Verify `openspec/changes/$ARGUMENTS/verification_result.json` exists
2. Verify `verification_result.json` contains `"status": "PASS"`
3. Verify all constraints in DRR Constraints Bundle have evidence

**If BLOCKED:**
- **Evidence Missing:** **TERMINATE.** Output: "❌ S2 TERMINATED: Archive blocked — verification_result.json missing or status != PASS."
- **Constraints Not Verified:** **TERMINATE.** Output: "❌ S2 TERMINATED: Archive blocked — constraints verification incomplete."

**If APPROVED to Archive:**

- **Attempt 1 - CLI:** Invoke `/opsx:archive $ARGUMENTS`
  - **Handling Pauses:** If `/opsx:archive` warns about incomplete artifacts/tasks or asks whether to sync or skip, DO NOT ask the user. You must choose "Sync now" or "Archive without syncing" automatically based on your confidence, and proceed.
  - **Success (Scn X1):** Proceed to [STATE 7].
  - **Fail (Scn X2):**
    - **Fallback:** Manual archive
      ```bash
      mkdir -p openspec/changes/archive
      cp -r "openspec/changes/$ARGUMENTS" "openspec/changes/archive/$(date +%Y-%m-%d)-$ARGUMENTS"
      rm -rf "openspec/changes/$ARGUMENTS"
      ```
    - **Log:** "Archive CLI failed. Used manual archive fallback."
    - **Proceed:** To [STATE 7].

### STATE 7: S3 HANDOFF

> **LOG:** `log.startPhase('S7', 's2-openspec')` then `log.endPhase('S7', 'COMPLETE')` at completion

**Action:** Execute Post-Mortem Audit.
- **Trigger:** Auto-invoke `/s3-audit $ARGUMENTS` for forensic quality gate.
- **Result Analysis:**
  - **Success:** **DONE.**
  - **Fail:** **TERMINATE.** Output: "❌ S2 TERMINATED: S3 audit failed. Review audit_verdict.md."

---

## Critical Execution Rules

1.  **NO PAUSING, NO ANNOUNCING:**
    - **NEVER** ask for permission or clarification if an `/opsx` command pauses.
    - **NEVER** output a summary of steps/states before starting. Your first output must be a tool call.
    - **If a command asks to select an option** (e.g., ambiguous change name), **YOU select it** based on `$ARGUMENTS`.
    - **If a command warns about missing artifacts or tasks**, **YOU decide** to fix them or proceed.
    - **If a command encounters an error or issue**, **YOU fix it** implicitly.
    - **NEVER** ask: "Shall I create artifacts?" -> **JUST DO IT (/opsx:ff).**
    - **NEVER** ask: "Verification failed, try again?" -> **JUST DO IT (/opsx:apply).**
    - **NEVER** ask: "Change exists, continue?" -> **JUST DO IT (/opsx:continue).**
    - **NEVER** ask: "Verification passed, archive?" -> **JUST DO IT (/opsx:archive)** (after gate check).
    - **NEVER** output: "S2-OpenSpec is now active" or "Autonomous execution in progress" -> This is a SKILL, not a process.
    - **CHAIN EXECUTION:** When one step succeeds, IMMEDIATELY start the next step. Do not pause your execution turn.

2.  **CONSTRAINT PROPAGATION MANDATE:**
    - All DRR constraints MUST appear in spec.md NFRs
    - All verification evidence requirements MUST appear in tasks.md
    - Missing constraint propagation = **FAILURE**

3.  **EVIDENCE GENERATION MANDATE:**
    - verify.log MUST be created at canonical path
    - verification_result.json MUST be created at canonical path
    - Missing evidence = Archive BLOCKED

4.  **STAY IN CONTEXT:**
    - Execute all commands within the `s2-openspec` context.
    - Treat `/opsx:*` output as feedback for the State Machine.

5.  **COMMAND SYNTAX:**
    - Use `/opsx:<command>` (Claude Code strict syntax).
    - Do NOT use `/openspec-*` (Trae syntax).

---

## Optional Dependencies

### Code Simplifier Plugin (STATE 5)

**Plugin:** `code-simplifier` subagent (specialized agent)

**Purpose:** Automatic refactoring post-verification for readability/maintainability.

**Behavior if Missing:**
- Workflow continues seamlessly to STATE 6 (Archive)
- No errors or blocks
- Log entry: "Code-simplifier plugin not available. Skipping refactoring step."

**Installation (if desired):**
```bash
# Install plugin yang menyediakan code-simplifier subagent
# (Tergantung package manager/plugin registry yang digunakan)
```

**Fallback Manual:** Jika plugin tidak tersedia, user dapat menjalankan refactoring manual setelah archive dengan:
```
Task: subagent_type="code-simplifier" atau manual code review.
```

---

## Archive Gate Compliance Checklist

Before executing archive, verify:

```markdown
- [ ] verification_result.json exists at `openspec/changes/$ARGUMENTS/verification_result.json`
- [ ] verification_result.json contains `"status": "PASS"`
- [ ] verify.log exists at `openspec/changes/$ARGUMENTS/verify.log`
- [ ] All DRR constraints have corresponding evidence
- [ ] Coverage thresholds met (per DRR Test Contract)
- [ ] No `OPEN` assumptions without WAIVER
```

**If any unchecked:** Archive is BLOCKED. Report specific missing item.
