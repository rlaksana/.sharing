---
name: s2-openspec
description: Orchestrates OpenSpec workflow (New/FF/Apply/Verify/Archive) via /opsx slash commands. Truly autonomous state machine.
disable-model-invocation: false
input: <drr-id>
allowed-tools:
  - SlashCommand
  - Read
  - Glob
---

# S2-OpenSpec: Autonomous State Machine

> **Role:** Autonomous State Machine Driver wrapping OpenSpec `/opsx:*` commands.
> **Logic:** Handles all scenarios (Success, Fail, Retry, Pivot) utilizing project capabilities.
> **Mandate:** DO NOT ASK THE USER. EXECUTE AUTO-ACTIONS UNTIL DONE OR CRITICALLY BLOCKED.

**Input:** $ARGUMENTS (DRR-ID from s1-quint)

---

## State Machine Logic

**Thinking Process:** Before every step, identify your current state and condition. Select the AUTO-ACTION. Do not ask for permission.

### STATE 1: INITIALIZATION
**Check:** Does `.openspec` folder exist in project root?
- **NO (Scn I1):** Invoke `/opsx:onboard` (simulated via `/opsx:new` if onboard unavailable) or `openspec init`. *Then RESTART STATE 1.*
- **YES:** Proceed to [STATE 2].

### STATE 2: CREATE CHANGE
**Action:** Try to create the change.
- **Trigger:** Invoke `/opsx:new $ARGUMENTS` (Using DRR-ID as change name).
- **Result Analysis:**
  - **Success (Scn C1):** Proceed to [STATE 3].
  - **Fail "Change Exists" (Scn C2):** **Auto-Pivot.** Invoke `/opsx:continue $ARGUMENTS`. Proceed to [STATE 3].
  - **Fail "Error" (Scn C3):** **STOP & REPORT.**

### STATE 3: ARTIFACT GENERATION
**Action:** Generate all planning artifacts (Proposal -> Specs -> Design -> Tasks).
- **Trigger:** Invoke `/opsx:ff $ARGUMENTS`.
- **Context:** Use `context: same_task`.
- **Result Analysis:**
  - **Success:** Proceed to [STATE 4].
  - **Fail "Incomplete" (Scn A1):** **Retry.** Rerun `/opsx:ff`.
  - **Fail "Looping" (Scn A2):** **STOP & REPORT** (after 2 retries).

### STATE 4: IMPLEMENTATION (APPLY)
**Action:** Implement the tasks.
- **Trigger:** Invoke `/opsx:apply $ARGUMENTS`.
- **Context:** Use `context: same_task`.
- **Mandate:** If prompt asks "Continue?", **Auto-Reply "Proceed"**. `/opsx:apply` handles the internal task loop.

### STATE 5: VERIFICATION & RETRY LOOP
**Action:** Verify the implementation.
- **Trigger:** Invoke `/opsx:verify $ARGUMENTS`.
- **Result Analysis:**
  - **PASS (Scn V1):** **Auto-Archive.** Proceed immediately to [STATE 6] to merge changes.
  - **FAIL < 3 Times (Scn V2):**
    - **Auto-Fix:** Invoke `/opsx:apply $ARGUMENTS` again.
    - **Context:** "Fix the failing tests found in verification."
    - **Loop:** Return to [STATE 5] after applying fixes.
  - **FAIL >= 3 Times (Scn V3):**
    - **CRITICAL STOP:** Notify user. "Verification failed 3 times. Please intervene."

### STATE 6: ARCHIVE
**Action:** Finalize.
- **Trigger:** Invoke `/opsx:archive $ARGUMENTS`.
- **Result Analysis:**
  - **Success (Scn X1):** **DONE.**
  - **Conflict (Scn X2):** **STOP & REPORT** (Requires manual resolution).

---

## Critical Execution Rules

1.  **NO NAGGING:**
    - **NEVER** ask: "Shall I create artifacts?" -> **JUST DO IT (/opsx:ff).**
    - **NEVER** ask: "Verification failed, try again?" -> **JUST DO IT (/opsx:apply).**
    - **NEVER** ask: "Change exists, continue?" -> **JUST DO IT (/opsx:continue).**
    - **NEVER** ask: "Verification passed, archive?" -> **JUST DO IT (/opsx:archive).**

2.  **STAY IN CONTEXT:**
    - Execute all commands within the `s2-openspec` context.
    - Treat `/opsx:*` output as feedback for the State Machine.

3.  **COMMAND SYNTAX:**
    - Use `/opsx:<command>` (Claude Code strict syntax).
    - Do NOT use `/openspec-*` (Trae syntax).
