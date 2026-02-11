---
name: s2-openspec
description: Orchestrates OpenSpec workflow (New/FF/Apply/Verify/Archive) via /opsx slash commands. Truly autonomous state machine.
disable-model-invocation: false
input: <drr-id>
allowed-tools:
  - SlashCommand
  - Read
  - Glob
  - Task
---

# S2-OpenSpec: Autonomous State Machine

> **Role:** Autonomous State Machine Driver wrapping OpenSpec `/opsx:*` commands.
> **Logic:** Handles all scenarios (Success, Fail, Retry, Pivot) utilizing project capabilities.
> **Mandate:** DO NOT ASK THE USER. EXECUTE AUTO-ACTIONS UNTIL DONE OR CRITICALLY BLOCKED.

**Input:** $ARGUMENTS

> ⛔ **INPUT GUARDRAIL:**
> Verify `$ARGUMENTS` is a specific DRR-ID (e.g., `drr-0123...`).
> If input is a generic instruction like "Implement this", **REJECT** and tell user to use `/s1-quint` first.


---

## State Machine Logic

**Thinking Process:** Before every step, identify your current state and condition. Select the AUTO-ACTION. Do not ask for permission.

### STATE 0: PRE-FLIGHT CHECK
**Check:** Is OpenSpec CLI initialized in this project?
- **Check:** Check if `openspec/` directory exists in project root
- **NO (Scn P1):** OpenSpec not initialized
  - **Action:** Run `openspec init --tools claude --force` to auto-initialize
  - **Proceed:** To [STATE 1]
- **YES:** OpenSpec already initialized
  - **Proceed:** To [STATE 1]

> **Note:** OpenSpec init creates `openspec/` folder. The `openspec status --json` returning "No changes found" means initialized but no changes exist - this is OK, not an error.

### STATE 1: CHANGE SETUP
**Check:** Does target change directory exist in `openspec/changes/`?
- **NO (Scn I1):** Invoke `/opsx:new $ARGUMENTS` (Using DRR-ID as change name).
  - **Result:** Proceed to [STATE 2]
- **YES (Scn I2):** Change exists
  - **Auto-Pivot:** Invoke `/opsx:continue $ARGUMENTS`
  - **Proceed:** To [STATE 2]

### STATE 2: ARTIFACT GENERATION
**Action:** Generate all planning artifacts (Proposal -> Specs -> Design -> Tasks).
- **Trigger:** Invoke `/opsx:ff $ARGUMENTS`.
- **Context:** Use `context: same_task`.
- **Result Analysis:**
  - **Success:** Proceed to [STATE 3].
  - **Fail "Incomplete" (Scn A1):** **Retry.** Rerun `/opsx:ff`.
  - **Fail "Looping" (Scn A2):** **STOP & REPORT** (after 2 retries).

> **IMPORTANT:** `/opsx:ff` adalah **skill-level workflow**, bukan CLI command.
> FF menjalankan sequence: `openspec new change` → `openspec status` → `openspec instructions` → create artifacts.
> Ini adalah abstraction layer di atas OpenSpec CLI, bukan direct command mapping.

### STATE 3: IMPLEMENTATION (APPLY)
**Action:** Implement the tasks.
- **Trigger:** Invoke `/opsx:apply $ARGUMENTS`.
- **Context:** Use `context: same_task`.
- **Mandate:** If prompt asks "Continue?", **Auto-Reply "Proceed"**. `/opsx:apply` handles the internal task loop.

### STATE 4: VERIFICATION & RETRY LOOP
**Action:** Verify the implementation.
- **Trigger:** Invoke `/opsx:verify $ARGUMENTS`.
- **Result Analysis:**
  - **PASS (Scn V1):** **Auto-Simplify.** Proceed immediately to [STATE 5] for code simplification.
  - **FAIL < 3 Times (Scn V2):**
    - **Auto-Fix:** Invoke `/opsx:apply $ARGUMENTS` again.
    - **Context:** "Fix the failing tests found in verification."
    - **Loop:** Return to [STATE 4] after applying fixes.
  - **FAIL >= 3 Times (Scn V3):**
    - **CRITICAL STOP:** Notify user. "Verification failed 3 times. Please intervene."

### STATE 5: CODE SIMPLIFICATION
**Action:** Refactor for clarity and maintainability.
- **Pre-Check:** Attempt to invoke `Task` tool with `subagent_type="code-simplifier:code-simplifier"`.
- **Context:** "Simplify and refine code from the recently completed implementation. Focus on: removing redundancy, improving naming, reducing nesting, extracting meaningful functions, and enhancing readability. Preserve ALL verified behavior."
- **Result Analysis:**
  - **Success (Scn S1):** Proceed to [STATE 6] to archive.
  - **No Changes Needed (Scn S2):** Proceed to [STATE 6] to archive.
  - **Subagent Unavailable (Scn S3):** **Auto-Fallback.** Log: "Code-simplifier plugin not available. Skipping refactoring step." Proceed to [STATE 6].
  - **Fail/Critical Error (Scn S4):** **STOP & REPORT.** "Code simplification encountered issues. Manual review required."
- **Mandate:** This step runs automatically post-verification. Gracefully skip if plugin unavailable.
- **Note for Sharing:** This step requires the `code-simplifier` plugin. If unavailable, workflow continues without refactoring.

### STATE 6: ARCHIVE
**Action:** Finalize.

**Known Issue:** `openspec archive` CLI memiliki interactive prompt untuk spec sync yang tidak dapat di-bypass dengan flag. Ini menyebabkan timeout dalam automation.

**Strategy - Try CLI first, fallback to manual:**

- **Attempt 1 - CLI:** Invoke `/opsx:archive $ARGUMENTS`
  - **Success (Scn X1):** Proceed to [STATE 7].
  - **Interactive Prompt/Timeout (Scn X2):**
    - **Auto-Fallback:** Manual archive
      ```bash
      mkdir -p openspec/changes/archive
      cp -r "openspec/changes/$ARGUMENTS" "openspec/changes/archive/$(date +%Y-%m-%d)-$ARGUMENTS"
      rm -rf "openspec/changes/$ARGUMENTS"
      ```
    - **Log:** "openspec archive requires interactive input. Used manual archive fallback."
    - **Proceed:** To [STATE 7].
  - **Conflict/Error (Scn X3):** **STOP & REPORT** (Requires manual resolution).

### STATE 7: S3 HANDOFF
**Action:** Offer Post-Mortem Audit.
- **Trigger:** Ask user: "Archive successful. Run forensic audit? (y/n)"
- **Result Analysis:**
  - **User "y" / "yes":** Invoke `/s3-audit $ARGUMENTS`.
  - **User "n" / "no":** **DONE.**

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

---

## Optional Dependencies

### Code Simplifier Plugin (STATE 6)

**Plugin:** `code-simplifier` subagent (specialized agent)

**Purpose:** Automatic refactoring post-verification for readability/maintainability.

**Behavior if Missing:**
- Workflow continues seamlessly to STATE 7 (Archive)
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
