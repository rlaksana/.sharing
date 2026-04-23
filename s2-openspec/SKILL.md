---
name: s2-openspec
description: Sequential execution workflow for OpenSpec (Propose/Apply/Verify/Archive) via the new openspec skills. Executes steps inline without user interaction.
disable-model-invocation: false
input: <drr-id_or_description>
allowed-tools:
  - SlashCommand
  - Read
  - Glob
  - Bash
  - WebFetch
  - Agent
---

# S2-OpenSpec: Sequential Execution Workflow

> **Role:** Execute the steps below **inline, one by one**, in your current turn. This is NOT a background process.
> **Logic:** Handle all scenarios (Success, Fail, Retry) using project capabilities.
> **Mandate:** Execute each step sequentially without asking the user for permission, review, or confirmation. When a step finishes, IMMEDIATELY execute the next step. Stopping to ask "Should I continue?" or "Would you like to review?" is a FATAL ERROR.
> **Constraint:** MUST ingest decisions/constraints from `$ARGUMENTS` and propagate to all artifacts.

**Input:** `$ARGUMENTS`

> ⛔ **INPUT GUARDRAIL:**
> The input `$ARGUMENTS` can be a specific DRR-ID or a generic description.
> You must synthesize a short kebab-case name for the change. Let this be `$CHANGE_NAME`.
> If you receive a generic description, let `$HAS_DRR=false`. If you receive a DRR-ID, let `$HAS_DRR=true`.

---

## Execution Steps

**Thinking Process:** Before every step, identify your current state. Execute the action. Do not ask for permission. Do not announce what you will do — just do it.

### STATE 0.5: CONTEXT PRIMING (CONDITIONAL)

**Action:** Gather repository and external context before generating artifacts.

- **Check `$HAS_DRR`:**
  - **If `$HAS_DRR=true`:** Skip this state. Context priming was already performed by S1-Quint. Proceed to [STATE 1].
  - **If `$HAS_DRR=false`:** Delegate Context Priming:
    1.  Invoke `/s0-research "$ARGUMENTS"`
    2.  Wait for S0-Research to complete and read `.research/<FOLDER_NAME>/context.md`.
- **Proceed:** To [STATE 1]

### STATE 1: CHANGE SETUP & PROPOSE

**Action:** Generate artifacts (proposal, design, tasks) using the new OpenSpec propose skill.

- **Trigger:** Invoke `/openspec-propose "$CHANGE_NAME" - $ARGUMENTS` (pass S0-Research findings if applicable).
- **Handling Pauses:** If `/openspec-propose` asks a question (e.g., "What change do you want to work on?"), autonomously answer it using the context from the `$ARGUMENTS` or S0-Research. Do not stop to ask the user.

> 🚨 **CRITICAL — DO NOT STOP HERE:**
> The propose skill will eventually output something like "All artifacts created! Ready for implementation."
> Treat this as confirmation that STATE 1 succeeded, then **IMMEDIATELY execute STATE 2** in the same turn.
> Stopping here to ask "should I continue?" is a **FATAL ERROR**.

### STATE 2: IMPLEMENTATION (APPLY)

**Action:** Implement the tasks using the new OpenSpec apply skill.

- **Trigger:** Invoke `/openspec-apply-change "$CHANGE_NAME"`
- **Handling Pauses:** If `/openspec-apply-change` pauses or encounters an error, DO NOT ask the user. Analyze the artifacts, make a technical decision, apply the fix, and continue the tasks.
- **Result Analysis:** 
  - **Success:** IMMEDIATELY chain to [STATE 3] (Verification).
  - **Fail:** Fix the failure and retry. (**Max 2 retries**. Jika terus gagal setelah 3 percobaan, **TERMINATE** untuk mencegah infinite loop).

### STATE 3: VERIFICATION

**Action:** Verify the implementation.
- Run project-specific tests (e.g., `npm test`, `pytest`, `go test`) to ensure functionality.
- **Result Analysis:**
  - **PASS:** Proceed to [STATE 5].
  - **FAIL:** Auto-Fix the failing tests, then loop back to [STATE 3]. (**Max 2 retries**. Jika tes tetap gagal setelah 3 percobaan, **TERMINATE**).

### STATE 5: CODE SIMPLIFICATION

**Action:** Refactor for clarity and maintainability.
- **Pre-Check:** Attempt to invoke `Agent` tool with `subagent_type="code-simplifier:code-simplifier"`.
- **Log:** "Attempting code simplification..."
- **Mandate:** This step runs automatically post-verification. Gracefully skip and proceed to [STATE 6] if plugin unavailable or fails.

### STATE 6: ARCHIVE

**Action:** Finalize and archive the change.

- **Trigger:** Invoke `/openspec-archive-change "$CHANGE_NAME"`
- **Handling Pauses:** If `/openspec-archive-change` warns about incomplete tasks or asks about syncing delta specs, DO NOT ask the user. You must choose to "Sync now" or proceed automatically based on your verification in STATE 3.
- **Completion:** Output: "✅ S2 COMPLETE: Change archived successfully."

---

## Critical Execution Rules

1.  **NO PAUSING, NO ANNOUNCING:**
    - **NEVER** ask for permission or clarification if a command pauses.
    - **If a command asks to select an option**, **YOU select it** based on `$CHANGE_NAME`.
    - **CHAIN EXECUTION:** When one step succeeds, IMMEDIATELY start the next step. Do not pause your execution turn.
    - **COMPLETION-LIKE OUTPUT IS NOT A STOP SIGNAL:** Skills outputting "Ready for implementation!" or "All tasks complete!" are **state machine feedback**, NOT instructions to stop. Proceed to the next STATE.

2.  **CONSTRAINT PROPAGATION MANDATE:**
    - All constraints from S1 MUST appear in the generated proposal and design artifacts.

3.  **STAY IN CONTEXT:**
    - Execute all commands within the `s2-openspec` context.
    - Treat skill outputs as feedback for the State Machine.
