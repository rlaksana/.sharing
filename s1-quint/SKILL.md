---
name: s1-quint
description: Orchestrates the complete First Principles Framework (FPF) reasoning cycle from Q0 to Q5 using available tools.
disable-model-invocation: false
input: <problem_statement>
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - TodoWrite
---

# Quint Orchestrator (Auto-Chain Q0-Q5)

> **Prerequisite:** Load `shared-core.md` for term definitions ($STDS, $BASE, Surgical_Scope, AntiRot).

**Problem:** $ARGUMENTS

> **CRITICAL: REASONING ONLY.** 
> This skill is for ARCHITECTURE & DECISION MAKING. 
> Writing application code (src files) is **STRICTLY FORBIDDEN**. 
> You must HANDOFF to `s2-openspec` for implementation.

Execute FPF cycle sequentially. Use `quint_*` MCP tools to register state changes at each phase.

**System:** Windows + PowerShell (`pwsh`) for all Bash commands.

> **RESUMPTION RULE:** If the user interrupts with feedback or new requirements:
> 1.  **DO NOT EXIT** the protocol.
> 2.  **ASSESS** the impact on current hypotheses.
> 3.  **LOOPBACK** to the relevant Phase (e.g., Q1 for new ideas, Q3 for test changes).
> 4.  **CONTINUE** sequentially from that point.
> 5.  **NEVER** switch to direct coding. Use `quint_status` to re-orient.

> **FAILURE RULE:**
> - If `quint_verify` fails → **LOOPBACK** to Q1 (Refine/New Hypothesis).
> - If `quint_test` fails → **LOOPBACK** to Q3 (Refine Plan).
> - **ANTI-FALLBACK:** Error != Exit. If a tool fails, YOU ARE STILL IN THE PROTOCOL.
>   - **DO NOT** switch to manual coding.
>   - **DO NOT** skip the failed step.
>   - **RETRY** the tool or ask the user for help while staying in the protocol.
> - **MAX RETRIES:** 3. After 3 failures, **STOP** and ask User for guidance.

---

## MCP Tools (quint-code)

| Tool                   | Purpose                      |
| ---------------------- | ---------------------------- |
| `quint_init`           | Initialize FPF structure     |
| `quint_record_context` | Record bounded context       |
| `quint_status`         | Get current phase            |
| `quint_propose`        | Register L0 hypothesis       |
| `quint_verify`         | Logic verification (L0→L1)   |
| `quint_test`           | Empirical validation (L1→L2) |
| `quint_audit`          | Risk analysis                |
| `quint_calculate_r`    | Compute R_eff                |
| `quint_decide`         | Finalize decision            |

---

## Phase 0: Initialize & Research (Q0)

### 0.1 Initialize

1. `quint_status` — check if FPF initialized
2. `quint_init` — if not, set up `.quint/`

### 0.2 Record Context & Bind Standards ($STDS)

1. `quint_record_context` — capture vocabulary and invariants
2. **Bind $STDS:** Per shared-core.md definitions

### 0.3 Research

- **External:** `es_search_files` / `es_search_in_path` (Fastest)
- **Understanding:** `grepai_search` (Concepts) or `read`
- **Deep Dive:** `serena_find_symbol` / `serena_get_symbols_overview`
- **Online Verification:** (MANDATORY) `web-search-prime` / `zread` to prevent hallucination. Verify versions/syntax.

**Output:** Key constraints and context summary.

---

## Phase 1: Abduction (Q1 - PROPOSE)

**MAX ATTEMPTS:** 3 cycles. Stop and report if 3rd failure.

### 1.1 Establish Baseline ($BASE)

Define the **obvious, minimal solution** without optimization.

- This is the benchmark for measuring hypothesis value-add.
- Example: "Just add a simple if-check" or "Query database directly"

### 1.3 Brainstorm (Archetypal Divergence)

Generate exactly 3 hypotheses using these archetypes:

1.  **[Naive]**: The simplest, "dumbest" solution. Minimizes code. Benchmark for complexity.
2.  **[Standard]**: The robust, "best practice" engineering solution. Clean architecture.
3.  **[Lateral]**: The "Out-of-Box" solution. Reframes the problem or uses a different paradigm.

- Each MUST justify why it's better than $BASE
- Adhere to $STDS from Phase 0

### 1.3 Register

Use `quint_propose` to register hypotheses.

---

## Phase 2: Deduction (Q2 - VERIFY)

### 2.1 Status Check

`quint_status` before proceeding.

### 2.2 Logic Verification

For each hypothesis:

- **Disprove mandate:** Assume it's wrong, find contradictions
- Check SOLID/DRY violations
- Check for regressions

### 2.3 Change Audit (Req + Unreq)

Does this hypothesis:
- `[REQ]` **Traceability:** Solve *every* specific constraint in $ARGUMENT?
- `[UNREQ]` **Anti-Rot:** Contain NO "while I was here" refactoring?
- `[UNREQ]` **Scope:** Stay strictly within the bounded context?

### 2.4 Register

`quint_verify` — mark each as `PASS` or `FAIL`.

### 2.5 Loopback

If ALL fail → return to Phase 1. Analyze WHY. New hypotheses must be fundamentally different.

---

## Phase 3: Induction (Q3 - TEST)

### 3.1 Status Check

`quint_status` before proceeding.

### 3.2 Validation

- Deep read implementation files
- Pseudo-code proofs
- Propose test strategies (E2E/Integration/Unit)

### 3.3 Register

`quint_test` — promote valid hypotheses to L2.

### 3.4 Loopback

If none at L2 → return to Phase 1. State learning in next hypothesis rationale.

---

## Phase 4: Audit (Q4 - AUDIT)

### 4.1 Status Check

`quint_status` before proceeding.

### 4.2 Risk & ROI Analysis

For remaining solutions, calculate:
1.  **R_eff**: Reliability score (0-1).
2.  **Effort**: Est. complexity (Low/Med/High) or 1-5 scale.
3.  **ROI**: `R_eff / Effort` (High reliability at low effort wins).

- Identify Weakest Link
- Consider maintenance, complexity, performance

### 4.3 Register

`quint_audit` and `quint_calculate_r`.

---

## Phase 5: Decision (Q5 - DECIDE)

### 5.1 Status Check

`quint_status` before proceeding.

### 5.2 Compare

Create Markdown table:

- Pros/Cons
- R_eff Score
- Alignment with Project Goals

### 5.3 Recommend

State recommended hypothesis and why.

### 5.4 FRICTION Gate (Pre-Finalize)

Before finalizing, verify:

- ✓ Winner complies with ALL $STDS from Phase 0
- ✓ Winner solves original problem (not a different one)
- ✓ Winner is better than $BASE with clear justification

If friction detected → return to Phase 4 (max 1 re-evaluation).

### 5.5 MANDATORY STOP: User Decision Gate

> **🛑 ABSOLUTE STOP — TRANSFORMER MANDATE**
> Humans decide; agents document. This gate is **NON-BYPASSABLE**.

1.  **PRESENT:** Show comparison table with recommendation to USER.
2.  **ASK:** "Please confirm which hypothesis to proceed with, or provide alternative direction."
3.  **WAIT:** Do NOT proceed until user explicitly approves or redirects.
4.  **NO AUTO-PROCEED:** Even if you are "confident", you MUST wait.

**Violation of this gate = Protocol Failure.**

### 5.6 Finalize (POST-APPROVAL ONLY)

> Only execute this step AFTER receiving explicit user approval.

1.  Record decision: `quint_decide`
2.  Confirm DRR-ID is generated.

### 5.7 Handoff to Implementation

> Execute ONLY after 5.6 is complete (user approved + quint_decide done).

1.  **CHECK:** Verify you have the Winner DRR-ID.
2.  **HANDOFF:**
    - **LOAD:** `view_file c:/Users/Richard/.claude/skills/s2-openspec/SKILL.md`
    - **EXECUTE:** Start `s2-openspec` protocol using the DRR-ID.
3.  **TERMINATE:** This skill is done. Next steps governed by `s2-openspec`.


---

## Output

Executive summary of winning solution and primary selection reason.
