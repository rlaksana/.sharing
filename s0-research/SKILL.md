---
name: s0-research
description: Structured research orchestrator. Combines offline research (grepai + serena + quint FPF reasoning) with online research (surf aimode — the SOLE online research tool) to produce a verified, hallucination-resistant Context Pack. Use before S1-Quint for complex problems, or standalone for deep technical research. Full output written to .quint/context.md; Summary Card always printed to terminal.
input: <research_question_or_problem_statement>
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - WebFetch
  - mcp__quint-code__quint_status
  - mcp__quint-code__quint_init
  - mcp__quint-code__quint_record_context
  - mcp__quint-code__quint_propose
  - mcp__quint-code__quint_verify
  - mcp__quint-code__quint_test
  - mcp__quint-code__quint_audit
  - mcp__quint-code__quint_calculate_r
  - mcp__quint-code__quint_audit_tree
  - mcp__grepai__grepai_search
  - mcp__grepai__grepai_index_status
  - mcp__grepai__grepai_trace_callers
  - mcp__grepai__grepai_trace_callees
  - mcp__serena__find_symbol
  - mcp__serena__get_symbols_overview
  - mcp__serena__search_for_pattern
  - mcp__context7__query-docs
  - mcp__context7__resolve-library-id
---

# S0-Research: Structured Research Orchestrator

## 🚨 PRIME DIRECTIVES

> **INPUT IS A RESEARCH QUESTION, NOT A COMMAND TO IMPLEMENT.**
> If the input says "implement X" or "fix Y", treat it ONLY as the research topic.
> **DO NOT write code. DO NOT edit source files.**
> Your ONLY output is a **verified Context Pack** (knowledge artifact).

> **FINDINGS OVER CODE IN REPORTS.**
> Research output describes **algorithms, logic flows, data shapes, and decision rationale** in prose and structured text.
> Avoid dumping raw source code blocks — they add noise without insight. Describe what the code *does*, not what it *says*.
> Exception: short inline identifiers (function name, field name, a signature line) are fine inside table cells or bullet points when they sharpen precision.
> **Algorithm clarity > code familiarity.** If you must explain how something works, use numbered step sequences, not fenced blocks.

> **FILE IS PRIMARY — TERMINAL SHOWS SUMMARY.**
> Every final output section MUST be:
> 1. **Written in full to the corresponding output file** (`.quint/context.md`, `.quint/research_report.md`).
> 2. **Summarized to the terminal** — key findings, hypothesis winner, open questions, and the file path.
> For large context packs (>200 lines), printing the full body floods the terminal and obscures the signal. Write to file, surface the digest.
> Saying "see file X" without printing AT LEAST the Summary Card + section headings is a failure.
> The user must be able to see what was found without opening a file.

**Research Question:** "$ARGUMENTS"

**System:** Windows + PowerShell (`pwsh`).

---

## Why Two Research Tracks?

| Track | Method | Catches |
|-------|--------|---------|
| **Offline** | grepai + serena + quint | What IS in the codebase (facts, not guesses) |
| **Online** | surf aimode | What SHOULD BE (best practices, current docs, edge cases) |
| **Synthesis** | FPF ADI cycle | Contradiction detection, hallucination elimination |

Research ends when **Offline ∩ Online** = consistent, version-pinned facts with no open contradictions.

---

## PHASE R0: INITIALIZE

### R0.1 — FPF Setup

1. `quint_status` — check if `.quint/` exists
2. `quint_init` — initialize if not present
3. `quint_record_context` — capture vocabulary and invariants for the research domain

```markdown
vocabulary: "<domain terms from the research question>"
invariants:
  - "All external references must be version-pinned (no 'latest')"
  - "Contradictions between offline and online tracks must be explicitly resolved"
  - "No assumption may remain OPEN without a WAIVER"
```

### R0.2 — Extract Research Dimensions

Decompose the research question into specific sub-questions:

| ID | Sub-Question | Track | Priority |
|----|-------------|-------|----------|
| RQ-1 | What does the existing codebase do in this area? | Offline | High |
| RQ-2 | What are the established solutions/patterns? | Online | High |
| RQ-3 | What are the known failure modes / edge cases? | Online | High |
| RQ-4 | What breaking changes or deprecations apply? | Online | Medium |
| RQ-5 | What are the version-specific constraints? | Both | Medium |

---

## PHASE R1: OFFLINE RESEARCH (Repo Truth)

> **Persona:** Code Archaeologist. Your job: extract FACTS, not guesses. Every claim must be traceable to a file:line.

### R1.1 — Index Health Check

```bash
# Verify grepai index is ready
grepai_index_status
```

If index not ready → proceed with serena-only offline research.

### R1.2 — Wide Discovery (grepai)

Run targeted searches for each noun/verb in the research question:

```bash
# Example for "Redis caching implementation":
grepai_search "redis"
grepai_search "cache"
grepai_search "TTL"
```

**Capture for each result:**
- File path + line range
- Symbol name (class/function/constant)
- Usage pattern (caller/callee relationship)

### R1.3 — Blast Radius Mapping

```bash
# Trace callers to understand what depends on relevant code
grepai_trace_callers "<key_symbol>"

# Trace callees to understand what this code depends on
grepai_trace_callees "<key_symbol>"
```

### R1.4 — Symbol Truth (serena)

Pin exact definitions, types, and contracts:

```bash
# Get overview of relevant file
serena.get_symbols_overview "<relevant_file>"

# Find specific symbol
serena.find_symbol "<symbol_name>"

# Search for patterns
serena.search_for_pattern "<pattern>" --relative_path "<scope>"
```

**For each key symbol, record:**
- Full signature (name, parameters, return type)
- File:line location
- Invariants and constraints from docstrings/comments
- Dependency relationships

### R1.5 — Offline Findings Register

After R1.1-R1.4, compile structured findings:

> **PATH RULE:** ALL file references MUST use absolute paths (e.g., `E:\clipper\aiclip\core\module.py:42`), never relative snippets or basenames.

```markdown
## Offline Findings (Repo Truth)

### Entrypoints
| Symbol | Full Path | Line | Role |
|--------|-----------|------|------|
| example_func | E:\clipper\aiclip\core\example.py | 42 | Entry point for X |

### Key Data Structures
| Name | Full Path | Line | Shape |
|------|-----------|------|-------|

### Existing Patterns
| Pattern | Full Path:Line | Notes |
|---------|----------------|-------|

### Blast Radius
| Full Path | Impact Type | Reason |
|-----------|-------------|--------|

### Code-Level Invariants
- INV-1: <what the code guarantees>
- INV-2: ...

### Open Questions (for Online track)
- OQ-1: <what offline can't answer>
- OQ-2: ...
```

---

## PHASE R2: ONLINE RESEARCH (External Truth)

> **Persona:** Skeptical Researcher. Assume nothing. Demand version-pinned sources. Treat undated claims as suspect.

### R2.1 — Form Targeted Queries

Convert each Open Question (OQ-*) and original RQ-* into specific, version-aware queries:

**Query Construction Rules:**
- Include version numbers: `"React 18 concurrent rendering"` not `"React rendering"`
- Include year for recency: `"PostgreSQL 16 partitioning 2024"`
- Ask for failure modes: `"redis cluster failover edge cases"`
- Ask for migration paths: `"migrating from X to Y breaking changes"`

### R2.2 — Primary Online Research (surf aimode — NOT WebSearch)

> **🚨 NO WebSearch TOOL:** Do NOT use the built-in `WebSearch` tool.
> This tool is unreliable and has been flagged as failing. Use `surf aimode` instead — it already performs web search internally via AI Mode.
> You can explicitly instruct surf aimode to perform web search in its prompt.
>
> **✅ WebFetch is OK:** Use the built-in `WebFetch` tool to retrieve specific pages when you have a known URL.
> `surf aimode` handles general research queries; `WebFetch` is for fetching exact pages.
>
> **⚠️ TIMEOUT:** Always use `--timeout 300` (or higher) to prevent CLI timeout.
> **⚠️ ANTI-TRUNCATION:** For large research outputs, redirect to file, then read the file.

Execute queries sequentially. For each query:

```bash
# Standard query (always include --timeout)
surf aimode --timeout 300 "<your targeted query>"

# For large/complex queries (save to file)
surf aimode --timeout 300 "<complex query>" > .quint/research_<topic>.md

# Explicitly instruct web search in prompt when needed
surf aimode --timeout 300 "search the web for <library_name> v<x.y.z> official documentation and breaking changes"
```

**Per query, extract:**
- 5-10 load-bearing facts (concrete, specific, testable)
- Source URLs (official docs preferred)
- Version/date stamps
- Known edge cases and failure modes
- Breaking changes from recent versions

### R2.3 — Library API Verification (context7)

For library-specific questions, use context7 for version-pinned API docs:

```bash
# Resolve library ID first
context7.resolve-library-id "<library_name>"

# Then query specific API
context7.query-docs --library_id "<id>" --query "<specific_api_question>"
```

### R2.4 — Contradiction Detection (**CRITICAL**)

Before proceeding, actively compare Offline vs Online findings:

| Dimension | Offline Says | Online Says | Status |
|-----------|-------------|-------------|--------|
| Pattern X | Implementation uses Y | Best practice is Z | ⚠️ CONFLICT |
| API signature | `func(a, b)` | `func(a, b, opts?)` | ✅ CONSISTENT |

**For each CONFLICT:**
- Determine which is authoritative (online usually wins for best practices, offline wins for constraints)
- Record resolution in the Assumption Ledger
- Flag as a risk if conflict cannot be resolved

### R2.5 — Online Findings Register

```markdown
## Online Findings (External Truth)

### Version-Pinned Facts
| Library/Concept | Version | Fact | Source | Date |
|----------------|---------|------|--------|------|
| <name> | <x.y.z> | <specific fact> | <url> | <YYYY-MM-DD> |

### Best Practices Found
- BP-1: <practice> (Source: <url>, Version: <x.y.z>)

### Known Failure Modes
- FM-1: <failure mode> — Trigger: <condition> — Mitigation: <approach>

### Breaking Changes / Deprecations
- BC-1: <change> in <version> — Migration: <path>

### Unanswered Questions
- UQ-1: <still unclear after research>
```

---

## PHASE R3: FPF SYNTHESIS (Hypothesis Generation & Verification)

> **Persona:** Structured Reasoner. Use FPF ADI cycle to transform raw findings into verified, competing solution hypotheses.

### R3.1 — Generate Hypotheses (Abduction / Q1)

Based on R1 + R2 findings, generate **3 competing solution approaches**:

1. **[Naive]** — Simplest approach, minimal change
2. **[Standard]** — Best practice from online research
3. **[Lateral]** — Non-obvious approach using different paradigm

For each hypothesis, call `quint_propose`:

```
quint_propose(
  title: "<hypothesis name>",
  content: "<detailed description of approach>",
  scope: "<where this applies — specific files/modules/layers>",
  kind: "system" | "episteme",
  rationale: JSON({
    "anomaly": "<what problem this solves>",
    "approach": "<how it solves it>",
    "alternatives_rejected": ["<why naive won't work>", "<why X was rejected>"]
  }),
  depends_on: ["<id of prerequisite holon if any>"]
)
```

**Hypothesis Template (fill for each):**
```markdown
### Hypothesis: [Naive | Standard | Lateral]
**Title:** <short name>
**Approach:** <1-2 sentences>
**Grounded In:**
  - Offline: <which repo facts support this>
  - Online: <which external facts support this>
**Assumptions:**
  - A1: <assumption> [VERIFIED by <source> | OPEN | WAIVER: <reason>]
**Risks:**
  - R1: <risk> — Probability: H/M/L — Impact: H/M/L
```

### R3.2 — Logical Verification (Deduction / Q2)

For each hypothesis, attempt to DISPROVE it:

**Verification Checklist:**
- [ ] Internal logical consistency (no self-contradictions)
- [ ] Compatible with offline INV-* invariants
- [ ] Compatible with online FM-* failure modes
- [ ] No SOLID violations
- [ ] No DRY violations in proposed approach
- [ ] Breaking changes (BC-*) accounted for

Call `quint_verify` after analysis:

```
quint_verify(
  hypothesis_id: "<id>",
  checks_json: JSON([
    {"check": "logical-consistency", "result": "PASS|FAIL", "notes": "<detail>"},
    {"check": "invariant-compliance", "result": "PASS|FAIL", "notes": "<INV-n: OK|VIOLATED>"},
    {"check": "failure-mode-coverage", "result": "PASS|FAIL", "notes": "<FM-n: HANDLED|UNHANDLED>"}
  ]),
  verdict: "PASS" | "FAIL" | "REFINE"
)
```

**If ALL hypotheses FAIL** → return to R3.1 with new constraints from failures. Max 3 cycles.

### R3.3 — Empirical Validation (Induction / Q3)

For each L1 hypothesis (passed Q2), gather empirical evidence:

**Internal Evidence:**
- Test feasibility: does the codebase support this approach?
- Blast radius: does it stay within identified boundaries?
- Mock implementation trace: step through the approach mentally against real file:line locations

**External Evidence:**
- Link to official docs (version-pinned) implementing this pattern
- Find benchmarks or case studies supporting the approach
- Identify known projects that implemented this successfully

Call `quint_test`:

```
quint_test(
  hypothesis_id: "<id>",
  test_type: "internal" | "research",
  result: "<evidence description with sources>",
  verdict: "PASS" | "FAIL" | "REFINE"
)
```

### R3.4 — Audit (Q4)

For all L2 hypotheses, compute trust scores:

```
quint_audit(
  hypothesis_id: "<id>",
  risks: "<consolidated risk analysis from R-* items>"
)

quint_calculate_r(holon_id: "<id>")
```

**Weakest Link Rule:** R_eff = min(all evidence scores). Never average.

---

## PHASE R4: CONTEXT PACK OUTPUT

> This is the PRIMARY DELIVERABLE of S0-Research. It feeds directly into S1-Quint (Q0) or serves as standalone research output.

### R4.1 — Close Assumption Ledger

Before output, all assumptions must be:
- `VERIFIED` — backed by evidence (file:line or version-pinned source)
- `WAIVER` — accepted risk with explicit justification and expiry date

Any `OPEN` assumption = Research Incomplete. Return to R1 or R2.

### R4.2 — Generate Context Pack

> **OUTPUT MANDATE:**
> 1. Write the full Context Pack content to `.quint/context.md` — always required.
> 2. Terminal output depends on pack size:
>    - **≤200 lines:** Print the ENTIRE Context Pack to the terminal.
>    - **>200 lines:** Print the Summary Card + all section headings + key findings. Full body is in the file. Flooding the terminal with hundreds of table rows obscures the signal — the file is authoritative.
> 3. Saying "see file X" without printing AT LEAST the Summary Card + section headings is a failure.
> Both file write and terminal summary are REQUIRED. Skipping either is a failure.

Content to print AND write to `.quint/context.md`:

```markdown
# Context Pack: <Research Topic>
Generated: <ISO timestamp>
Research Scope: "$ARGUMENTS"

---

## 1. Repo Truth (Offline Findings)

### Entrypoints
| Symbol | Full Path | Line | Purpose |
|--------|-----------|------|---------|

### Blast Radius
| Full Path | Reason | Impact |
|-----------|--------|--------|

### Code-Level Invariants
- INV-1: <invariant>

---

## 2. External Truth (Online Findings — Version-Pinned)

| Library/Doc | Version | Key Fact | Source URL | Date Accessed |
|-------------|---------|----------|------------|---------------|
| <name> | <x.y.z> | <fact> | <url> | <YYYY-MM-DD> |

**NO GENERIC REFERENCES:**
- ❌ "Latest docs" / "current version" / "stable"
- ✅ "React 18.3.1 (react.dev/reference, 2025-03-10)"

### Best Practices
- BP-1: <practice> (Source: <url>)

### Known Failure Modes  
- FM-1: <mode> — Mitigation: <approach>

---

## 3. Assumption Ledger

| ID | Assumption | Status | Evidence | Waiver Justification |
|----|------------|--------|----------|----------------------|
| A1 | <assumption> | VERIFIED | <source:line or url> | - |
| A2 | <assumption> | WAIVER | - | [Expires: <date>, Reason: <why>] |

**RULE:** No S1-Quint handoff if any OPEN items without WAIVER.

---

## 4. Synthesized Hypotheses (FPF L2)

### Ranked by R_eff

| Rank | Hypothesis ID | Title | R_eff | Effort | Approach Summary |
|------|---------------|-------|-------|--------|-----------------|
| 1 | <id> | <name> | <0-1> | H/M/L | <1-line summary> |

### Recommendation
**Winner:** <hypothesis_id> — <title>
**Rationale:** <why this beats alternatives>
**Key Risks:** <top 1-2 risks from Q4>

---

## 5. Contradictions Resolved

| Conflict | Offline Says | Online Says | Resolution |
|----------|-------------|-------------|------------|

---

## 6. Open Questions / Unanswered

- UQ-1: <still unclear — requires user input or additional research>

---

## 7. Negative Constraints (Anti-Patterns)

> These are as important as the positive findings. Explicitly telling the implementer what NOT to do prevents hallucinated convenience methods and known-bad patterns.

- NC-1: Do NOT use `<library/method>` — reason: `<deprecation/incompatibility/security>`
- NC-2: Do NOT assume `<env/service>` is available — must check: `<how>`
- NC-3: Avoid pattern `<X>` — use `<Y>` instead because: `<reason>`

---

## 8. Grounding Snippets

> Verbatim, minimal code blocks from the codebase or official docs that anchor the implementation. Providing exact source material reduces the implementer's urge to "guess" logic.

```python
# Snippet: <what this shows> — Source: <file:line or url>
<verbatim code, max 10-15 lines>
```

---

## 9. Test Contract (if applicable)

### Required Evidence for S1/S2
- [ ] Unit tests: <specific functions>
- [ ] Integration tests: <APIs/interfaces>

### Anti-Flake Rules
- [ ] No `setTimeout` without reason
- [ ] No random data without seeded RNG
- [ ] No live network calls in unit tests

### Coverage Thresholds
- Line: >= 80%
- Branch: >= 70%
```

---

## PHASE R5: REPORT & HANDOFF

### R5.1 — Research Report (Full Terminal Output + File Write)

> **MANDATORY SEQUENCE — NO SHORTCUTS:**
> 1. **Write the full Context Pack** (from R4.2) to `.quint/context.md`.
> 2. **Print the Summary Card** (below) to the terminal — always required.
> 3. **Print section headings + key findings** to terminal (for large packs, skip the full table bodies — they're in the file).
> 4. **Write the full report** to `.quint/research_report.md`.
> 5. Confirm: "Context Pack saved to `.quint/context.md`. Full report saved to `.quint/research_report.md`."
>
> **CRITICAL FAILURES (will be rejected):**
> - Printing zero terminal output — the Summary Card is always required.
> - Using snippet paths (`src/main.py`) instead of absolute paths (`E:\clipper\aiclip\core\module.py:42`).
> - Omitting key findings from the Summary Card.
>
> **REPORT CONTENT RULES:**
> - Describe every finding, hypothesis, contradiction, and resolution in full (in the file).
> - Use structured prose, tables, and numbered lists. Avoid raw fenced code dumps.
> - ALL file paths MUST be absolute.
> - For algorithmic descriptions, use numbered step sequences (1. … 2. … 3. …), not fenced blocks.

**Step 1: Write the full Context Pack content (from R4.2) to `.quint/context.md`.**

**Step 2: Then print the Summary Card:**

╔══════════════════════════════════════════════════════╗
║              S0-RESEARCH COMPLETE                    ║
╠══════════════════════════════════════════════════════╣
║ Topic: <research question>                           ║
║ Context Pack: .quint/context.md                      ║
╠══════════════════════════════════════════════════════╣
║ OFFLINE COVERAGE                                     ║
║   Files analyzed: <n>                                ║
║   Key symbols pinned: <n>                            ║
║   Code invariants found: <n>                         ║
╠══════════════════════════════════════════════════════╣
║ ONLINE COVERAGE                                      ║
║   Queries executed: <n>                              ║
║   Version-pinned facts: <n>                          ║
║   Failure modes documented: <n>                      ║
╠══════════════════════════════════════════════════════╣
║ FPF SYNTHESIS                                        ║
║   Hypotheses generated: <n>                          ║
║   Passed verification (L2): <n>                      ║
║   Recommended: <hypothesis title> (R_eff: <score>)   ║
╠══════════════════════════════════════════════════════╣
║ OPEN QUESTIONS: <n>                                  ║
║   <list if any>                                      ║
╠══════════════════════════════════════════════════════╣
║ NEXT STEP                                            ║
║   → /s1-quint <problem statement>  (use context.md)  ║
║   → OR review .quint/context.md directly             ║
╚══════════════════════════════════════════════════════╝

**Step 2: Print the Summary Card above to terminal.**
**Step 3: Write the full Context Pack + Summary Card to `.quint/research_report.md`.**
**Step 4: Confirm: "Context Pack saved to `.quint/context.md`. Full report saved to `.quint/research_report.md`."**

### R5.2 — Handoff Modes

**Mode A: Feed into S1-Quint**
When called from S1-Quint (Q0.2), S0-Research completes and returns control.
S1-Quint then reads `.quint/context.md` as its Context Pack.
S1-Quint **skips its own Q0.2** (research already done).

**Mode B: Standalone Output**
When called directly, present the Context Pack summary and await user direction.

---

## FAILURE RULES

| Condition | Action |
|-----------|--------|
| grepai index not ready | Proceed with serena-only offline (log: "⚠️ grepai unavailable, serena-only mode") |
| surf aimode fails/timeouts | Retry with `--timeout 600`. If Bash tool itself times out, increase Bash timeout. If still fails, use context7 as fallback for library API questions. Log the gap. |
| All 3 hypotheses FAIL Q2 | Regenerate with tighter scope. Log: "R3.1 retry N/3" |
| 3 consecutive R3 failures | TERMINATE. Output: "❌ S0 TERMINATED: Cannot generate valid hypotheses. Research inconclusive." |
| Open questions remain | List in UQ-* section. Do NOT block output. Surface to user. |
| Any OPEN assumption | BLOCK R4.2 until VERIFIED or WAIVER assigned. |

---

## ANTI-PATTERNS (DO NOT)

| Anti-Pattern | Why It's Wrong |
|-------------|----------------|
| Citing "latest" or "current" docs | Undated = unverifiable = hallucination risk |
| Skipping offline research for "obviously new" features | New features often touch old code; offline is mandatory |
| Running online research without targeted queries | Broad queries waste tokens and produce noise |
| Assuming online = ground truth over offline | Codebase invariants override general advice |
| Running Q1 without reading offline findings | Hypotheses grounded only in online = hallucination risk |
| Generating only 1 hypothesis | Single-option = anchoring bias = not FPF |
| Skipping contradiction check | Unresolved conflicts produce unreliable recommendations |

---

## INTEGRATION WITH SKILL CHAIN

```
S0-Research        →    S1-Quint     →    S2-OpenSpec
(Context Pack)          (DRR)             (Implementation)

STANDALONE MODE:
User → /s0-research → Context Pack → User reviews → decides next step

S1-INTEGRATED MODE:
S1-Quint Q0.2 calls S0-Research → Context Pack auto-feeds Q0.3
```

**When S1 calls S0:**
- S1 passes its `$ARGUMENTS` as the research question
- S0 writes `.quint/context.md`
- S0 returns (does NOT call S1 back — avoids recursion)
- S1 continues from Q0.3 using the populated context.md

---

## QUICK REFERENCE

| Phase | Goal | Key Tools | Output |
|-------|------|-----------|--------|
| R0 | Setup FPF + decompose question | quint_init, quint_record_context | Bounded context, RQ-* list |
| R1 | Mine codebase for facts | grepai, serena | Offline Findings Register |
| R2 | Mine external sources | surf aimode, context7 | Online Findings Register |
| R3 | Synthesize via FPF ADI | quint_propose/verify/test/audit | L2 hypotheses, R_eff scores |
| R4 | Produce Context Pack | Write `.quint/context.md` | Verified, version-pinned Context Pack |
| R5 | Report + handoff | — | Summary card, handoff to S1 or user |
