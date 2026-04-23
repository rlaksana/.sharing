---
name: s0-research
description: Structured research orchestrator using Sequential Grounding (Online -> Offline) + PRD for Hypothesis Synthesis. Combines online research (surf aimode --pro) for External Truth with offline research (repomix + grepai + serena) for Repo Truth to produce a verified Context Pack. Flow: R0 (setup) → R0.5 (query refinement) → R1 (Online Prime) → R2 (Offline Prime) → FPF analysis → FPF.5 (recursive gap loop, max 3x) → PRD Synthesis (Hypotheses) → grounded. Always use surf aimode --pro. Use before S1-Quint for complex problems. Full output to .research/<topic-slug>-<timestamp>/context.md; Summary Card to terminal. Each run creates a human-readable folder (e.g., "redis-caching-python-20260316-143052") to preserve history.
input: <research_question_or_problem_statement>
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - WebFetch
  - mcp__repomix__pack_codebase
  - mcp__repomix__attach_packed_output
  - mcp__repomix__grep_repomix_output
  - mcp__repomix__read_repomix_output
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
> 1. **Written in full to the corresponding output file** (`.research/<FOLDER_NAME>/context.md`, `.research/<FOLDER_NAME>/research_report.md`).
> 2. **Summarized to the terminal** — key findings, hypothesis winner, open questions, and the file path.
> For large context packs (>200 lines), printing the full body floods the terminal and obscures the signal. Write to file, surface the digest.
> Saying "see file X" without printing AT LEAST the Summary Card + section headings is a failure.
> The user must be able to see what was found without opening a file.

**Research Question:** "$ARGUMENTS"

**System:** Windows + PowerShell (`pwsh`).

---

## Sequential Grounding: Online Prime → Offline Prime

| Phase | Method | Catches |
|-------|--------|---------|
| **R1 (Online)** | `surf aimode --pro` | What SHOULD BE (External Truth - best practices, docs, edge cases). **Always do this first** to establish a baseline. |
| **R2 (Offline)** | `repomix` + `grepai` + `serena` | What IS in the codebase (Repo Truth). Done **after** online research to verify how the code aligns with established practices or constraints. |
| **R3 Synthesis**| Parallel Refine & Define | Takes facts from R1 and R2 to generate competing solution hypotheses, refining them into a final recommendation. |

**Key Principle:** Research must follow a **Strict Sequence**. ALWAYS ground yourself in External Truth (Online) first before diving into Repo Truth (Offline) to prevent hallucinating convenience methods and to identify the actual "best practices" needed by the codebase.

Research ends when **Offline ∩ Online** = consistent, version-pinned facts with no open contradictions.

---

## PHASE R0: INITIALIZE

### R0.0 — Get Current Working Directory

Before starting, get the current working directory to use in file paths:

```bash
pwd
```

Store this as `<PROJECT_DIR>` for use in Summary Card and confirmation messages.

### R0.1 — Setup Research Context

1. **Extract topic slug from research question:**
   - Take the first 2-3 significant keywords from the research question
   - Convert to lowercase, replace spaces with hyphens, remove special chars
   - Example: "How to implement Redis caching in Python" → "redis-caching-python"

2. **Create human-readable research folder:**
   ```bash
   # Generate timestamp (YYYYMMDD-HHMMSS)
   TIMESTAMP=$(date +%Y%m%d-%H%M%S)

   # Extract slug from research question (manually or via script)
   # Example: "redis caching python" → "redis-caching-python"
   RESEARCH_SLUG="<extracted-slug>"

   # Combine: <slug>-<timestamp>
   RESEARCH_FOLDER="$RESEARCH_SLUG-$TIMESTAMP"
   mkdir -p ".research/$RESEARCH_FOLDER"
   ```
3. Store `$RESEARCH_FOLDER` as `<FOLDER_NAME>` for all subsequent file paths
4. Initialize research tracking file `.research/<FOLDER_NAME>/research_notes.md`

**Output folder example:**
```
.research/
├── redis-caching-python-20260316-143052/
│   ├── context.md
│   ├── research_report.md
│   └── research_notes.md
├── python-fastapi-auth-20260315-091230/
│   ├── context.md
│   └── ...
```

```markdown
# Research: <topic>
Started: <timestamp>

## Research Questions
| ID | Sub-Question | Track | Priority |
|----|-------------|-------|----------|
| RQ-1 | ... | Offline/Online | High/Medium |

## Open Questions
- OQ-1: ...

## Assumption Ledger
| ID | Assumption | Status |
|----|------------|--------|
```

### R0.2 — Extract Research Dimensions

Decompose the research question into specific sub-questions:

| ID | Sub-Question | Track | Priority |
|----|-------------|-------|----------|
| RQ-1 | What are the established solutions/patterns? | Online | High |
| RQ-2 | What are the known failure modes / edge cases? | Online | High |
| RQ-3 | What does the existing codebase do in this area? | Offline | High |
| RQ-4 | What breaking changes or deprecations apply? | Online | Medium |
| RQ-5 | What are the version-specific constraints? | Both | Medium |

**🚨 CRITICAL: Check for User-Provided Data**
Before proceeding, scan the research question for:
- Analytics data, metrics, A/B test results
- Performance measurements from their specific system/audience
- Historical data about their content/audience
- Any "my data shows...", "my experience is...", or specific numbers/percentages

If user data exists:
1. Flag in research notes: "USER_DATA_EXISTS = TRUE"
2. This will trigger mandatory R2.7 reconciliation step
3. ALL generic advice must be validated against user data before final output

### R0.5 — Query Refinement (Pre-Fetch Optimization)

> **CRITICAL:** Before executing R1/R2, refine the research queries to maximize recall.
> This solves the "Vocabulary Mismatch" problem where user phrasing doesn't match source text.

**Step 1: Decomposition**
Generate 3-5 distinct sub-queries from the main research question:

```
Main Question: "How to implement caching in this codebase?"
Sub-queries:
- "redis cache implementation"
- "in-memory cache TTL"
- "cache invalidation patterns"
- "memoization functions"
```

**Step 2: Synonym Expansion**
For each sub-query, generate variations:

```
"redis" → "redis", "memcached", "cache store"
" TTL" → "TTL", "time to live", "expiration", "eviction"
```

**Step 3: Operator Optimization**
Convert to search-engine-friendly queries:

```
# For offline (grepai/serena)
"cache" "TTL" "expiration"

# For online (surf aimode)
"site:stackoverflow.com cache TTL best practices 2024"
"filetype:pdf redis caching patterns"
```

**Output: Refined Query Set**
```markdown
## Refined Queries for R1/R2

### Online Queries (R1)
| ID | Query | Focus |
|----|-------|-------|
| IQ-1 | <query> | <topic> |
| IQ-2 | ... | ... |

### Offline Queries (R2)
| ID | Query | Scope |
|----|-------|-------|
| OQ-1 | <query> | <file patterns> |
| OQ-2 | ... | ... |
```

---

## PHASE R1: ONLINE RESEARCH (External Truth) — DO THIS FIRST

> **Persona:** Skeptical Researcher. Assume nothing. Demand version-pinned sources. Treat undated claims as suspect.
> **IMPORTANT:** Run R1 FIRST to establish truth before checking the codebase.

### R1.1 — Form Targeted Queries

Convert each Open Question (OQ-*) and original RQ-* into specific, version-aware queries:

**Query Construction Rules:**
- Include version numbers: `"React 18 concurrent rendering"` not `"React rendering"`
- Include year for recency: `"PostgreSQL 16 partitioning 2024"`
- Ask for failure modes: `"redis cluster failover edge cases"`
- Ask for migration paths: `"migrating from X to Y breaking changes"`

### R1.2 — Primary Online Research (surf aimode --pro — NOT WebSearch)

> **🚨 MANDATORY: Always use `surf aimode --pro`** for all online research queries.
> **🚨 NO WebSearch TOOL:** Do NOT use the built-in `WebSearch` tool.
> Use `surf aimode --pro` — it already performs web search internally via AI Mode.
>
> **✅ WebFetch is OK:** Use the built-in `WebFetch` tool to retrieve specific pages when you have a known URL.
> `surf aimode --pro` handles general research queries; `WebFetch` is for fetching exact pages.
>
> **⚠️ TIMEOUT:** Always use `--timeout 600` (or higher) to prevent CLI timeout.
> **⚠️ ANTI-TRUNCATION:** For large research outputs, redirect to file, then read the file.
> **⛔ SEQUENTIAL EXECUTION ONLY:** Do NOT run multiple `surf` commands in parallel. The Chrome extension's native messaging supports only ONE connection at a time. All requests must be executed sequentially. Parallel requests will queue up and timeout.

Execute queries. For each query:

```bash
# Standard query (ALWAYS use --pro flag)
surf aimode --pro --timeout 600 "<your targeted query>"

# For large/complex queries (save to file)
surf aimode --pro --timeout 600 "<complex query>" > .research/<FOLDER_NAME>/research_<topic>.md

# Explicitly instruct web search in prompt when needed
surf aimode --pro --timeout 600 "search the web for <library_name> v<x.y.z> official documentation and breaking changes"
```

**Per query, extract:**
- 5-10 load-bearing facts (concrete, specific, testable)
- Source URLs (official docs preferred)
- Version/date stamps
- Known edge cases and failure modes
- Breaking changes from recent versions

### R1.3 — Library API Verification (context7)

For library-specific questions, use context7 for version-pinned API docs:

```bash
# Resolve library ID first
context7.resolve-library-id "<library_name>"

# Then query specific API
context7.query-docs --library_id "<id>" --query "<specific_api_question>"
```

### R1.4 — Contradiction Detection (**CRITICAL**)

Before proceeding, actively compare Offline vs Online findings:

| Dimension | Offline Says | Online Says | Status |
|-----------|-------------|-------------|--------|
| Pattern X | Implementation uses Y | Best practice is Z | ⚠️ CONFLICT |
| API signature | `func(a, b)` | `func(a, b, opts?)` | ✅ CONSISTENT |

**For each CONFLICT:**
- Determine which is authoritative (online usually wins for best practices, offline wins for constraints)
- Record resolution in the Assumption Ledger
- Flag as a risk if conflict cannot be resolved

### R1.7 — User Data Reconciliation (**CRITICAL FOR NON-CODE RESEARCH**)

> **🚨 MANDATORY when user provides their own empirical data.**
> This step prevents the #1 research failure: overriding user data with generic best practices.

If the user's input includes any of the following, you MUST reconcile them:
- Analytics data, metrics, A/B test results
- Performance measurements from their specific system/audience
- Historical data about their content/audience
- Any "my data shows..." or "my experience is..." statements

**Reconciliation Protocol:**

1. **Extract User-Provided Facts** from the research question:
   - Create a table of ALL empirical data the user provided
   - Include exact numbers, percentages, dates

2. **Compare with Online Findings:**
   | User's Data | Online Generic Advice | Conflict? | Resolution |
   |-------------|---------------------|-----------|------------|
   | ≥60s performs 11x better (15,563 vs 1,365) | 15-30s optimal | ⚠️ CONFLICT | User data wins - empirical evidence trumps generic benchmark |

3. **Resolution Rules (CRITICAL):**
   - **User's empirical data ALWAYS wins** over generic best practices UNLESS:
     - User data is acknowledged as incomplete/unreliable
     - There's strong theoretical reason that contradicts user data (not just "best practice")
   - Generic advice should be flagged as "ADJUST" or "VALIDATE" against user data, NOT override it
   - If generic advice contradicts user data, state: "Generic X says Y, BUT your data shows Z. Default to your data."

4. **Document in Assumption Ledger:**
   | ID | Assumption | Status | Evidence |
   |----|------------|--------|----------|
   | UD-1 | User data is valid | VERIFIED | User provided specific metrics |

**Example of CORRECT resolution:**
```
| Duration | Generic: 15-30s optimal | Your data: ≥60s = 11x better | → Use your data |
```

**Example of WRONG resolution (DO NOT DO THIS):**
```
| Duration | Generic: 15-30s optimal | Your data: ≥60s = 11x better | → ⚠️ ADJUST to 15-30s |
```
↑ This is what caused the failure. Generic advice should NOT override user's own A/B data.

### R1.5 — Online Findings Register

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

### R1.6 — Grounding Step (VERIFY with surf aimode --pro)

> **CRITICAL:** After initial online research, ALWAYS verify findings with a grounding query using `surf aimode --pro`.

This step validates that the research answers are accurate and grounds them against authoritative sources:

```bash
# Ground/verify the research findings
surf aimode --pro --timeout 600 "Verify and summarize the key findings about <topic> from <source1>, <source2>. What are the most important facts and their sources?"
```

**Why grounding:**
- Cross-validate research results against authoritative sources
- Catch hallucinations or outdated information
- Ensure version-pinned facts are correct
- Identify any contradictions between sources

**Record grounding results:**
- Sources verified
- Key facts confirmed or corrected
- Any new findings from verification
- Update Online Findings Register if corrections needed

---

## PHASE R2: OFFLINE RESEARCH (Repo Truth) — THEN THIS

> **Persona:** Code Archaeologist. Your job: extract FACTS, not guesses. Every claim must be traceable to a file:line.
> **IMPORTANT:** Run R2 AFTER R1 is complete. Ground yourself in External Truth before searching the repo. 

### R2.1 — Repomix Wide Discovery (Cross-File Analysis)

```bash
# Pack current codebase for semantic search
repomix.pack_codebase --directory "<project_path>" --style xml --compress

# Or attach existing packed output
repomix.attach_packed_output --path "<path_to_packed_output>"

# Search for domain-specific terms
repomix.grep_repomix_output --outputId "<id>" --pattern "<search_term>"
```

**Purpose:** Get architectural overview and cross-file patterns before diving into specific symbols.

### R2.2 — Index Health Check

```bash
# Verify grepai index is ready
grepai_index_status
```

If index not ready → proceed with serena-only offline research.

### R2.3 — Wide Discovery (grepai)

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

### R2.4 — Blast Radius Mapping

```bash
# Trace callers to understand what depends on relevant code
grepai_trace_callers "<key_symbol>"

# Trace callees to understand what this code depends on
grepai_trace_callees "<key_symbol>"
```

### R2.5 — Symbol Truth (serena)

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

### R2.6 — Offline Findings Register

After R2.1-R2.4, compile structured findings:

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

## PHASE FPF: FIRST PRINCIPLES ANALYSIS (Problem Decomposition)

> **Persona:** First Principles Engineer. Decompose the problem to its fundamental truths, challenge assumptions, and identify breakthrough opportunities.
>
> **Input:** R1.5 (Online Findings) + R2.6 (Offline Findings)
> **Output:** FPF Analysis with core problem, invariants, radical options

After R2 completes (including grounding), apply FPF analysis to decompose the problem:

### FPF.1 — Problem Decomposition

Break the research question into fundamental components:

```
Core Question: "What are we really trying to solve?"
Sub-questions:
  - What is the core function? (not features)
  - What resources are truly required?
  - What are the physics/constraints?
  - What do customers/users actually need?
```

### FPF.2 — First Principles Analysis

For each component, apply first principles:

| Component | Traditional Assumption | First Principles Analysis |
|-----------|----------------------|-------------------------|
| Cost | "Industry standard is X" | What are raw materials/components at commodity price? |
| Performance | "Best available is Y" | What is the physical limit? |
| Distribution | "We need Z channel" | What does user actually need to discover? |
| Value | "Competitors charge A" | What value does user get? What would they pay? |

### FPF.3 — Constraint Breaking

Identify and challenge "impossible" constraints:

**Template:**
```
Constraint: [Industry assumption]
Why is it true? [List reasons]
Is it still valid? [Evidence check]
Alternative: [First principles solution]
Breakthrough: [How to achieve 10x improvement]
```

### FPF.4 — FPF Analysis Output

Compile the FPF analysis:

```markdown
## FPF Analysis Output

### Core Problem Definition
- **What:** [Core function in one sentence]
- **Why:** [First principles justification]
- **Cost structure:** [Commodity-based breakdown if applicable]

### Invariants (Must Preserve)
- INV-1: [Non-negotiable constraint from codebase]
- INV-2: [Non-negotiable constraint from research]

### Radical Options (If achieved, changes everything)
- OPT-1: [10x improvement path]
- OPT-2: [Alternative breakthrough approach]

### Constraints Challenged
- C1: [Old assumption] → [New first principles view]
- C2: ...

### Architecture Decision Points
- Selected approach: [Why this beats alternatives]
- Expected improvement: [% vs current]
- Technical risks: [And mitigation]
```

### FPF.5 — Recursive Gap Detection Loop

> **CRITICAL:** After FPF analysis, check for epistemic gaps. If gaps exist, loop back to R2 for refined research.
> This implements the "Deep Research" agent pattern (DeepSeek-R1, OpenAI o1-like reasoning loops).

**Gap Detection:**

| Gap Type | Detection Method | Action |
|----------|------------------|--------|
| **Epistemic Gap** | Claim lacks primary source | Flag, find source |
| **Reasoning Gap** | Logic chain incomplete | Fill missing steps |
| **Evidence Gap** | Weak supporting data | Gather more evidence |
| **Contradiction Gap** | Offline vs Online conflict | Resolve with verification |

**Loop Mechanism:**

```
FPF.4 Output
    ↓
Gap Detection Check
    ↓
┌─────────────────────────────────────┐
│  Any Gaps?                         │
│  - YES → Refine queries → Loop to R2│
│  - NO  → Proceed to R3             │
└─────────────────────────────────────┘
```

**Recursive Rules:**
- **Max Iterations:** 3 loops maximum
- **Query Refinement:** Each loop produces more targeted queries
- **Convergence:** Loop exits when no new gaps found OR max iterations reached

**Loop Tracking:**

```markdown
## FPF Loop Tracker

| Iteration | Gaps Found | Refined Queries | Status |
|-----------|------------|-----------------|--------|
| 1 | [list] | [queries] | CONTINUE/EXIT |
| 2 | ... | ... | CONTINUE/EXIT |
| 3 | ... | ... | EXIT (max) |
```

**If Max Iterations Reached with Open Gaps:**
- Document remaining gaps in "Open Questions" section
- Proceed to R3 with caveat
- Flag for human review

---

## PHASE R3: PRD SYNTHESIS (Hypothesis Generation)

> **Persona:** Integration Architect. Uses **Parallel Refine & Define** on the findings to generate multiple parallel HYPOTHESES, then refines and defines them into a final recommendation.
>
> **Input:** R1.5 + R2.6 + FPF Analysis + Grounding
> **Output:** PRD Synthesis with solution options

**Key Flow:**
- **R1 + R2:** Sequential Grounding (Online -> Offline)
- **FPF:** First Principles Analysis on research findings
- **PRD (R3):** Generates parallel hypotheses → Refines & Defines → Final Recommendation

### R3.1 — Hypothesis Generation (Parallel Tracks)

Instead of generating one single solution, use the findings from R1 and R2 to brainstorm **3 parallel hypothesis tracks**:

**Track A: The Standard Path**
- Based heavily on Online Best Practices (R1) combined with Current Architecture (R2)

**Track B: The First Principles Path**
- Based on FPF constraints, challenging the standard assumptions

**Track C: The Minimalist Path**
- The simplest possible offline implementation, relying minimally on external tools

### R3.2 — Convergence (Compare & Integrate)

Now, evaluate the 3 hypothesis tracks against each other using a Refine & Define matrix:

| Dimension | Track A | Track B | Track C | Resolution |
|-----------|---------|---------|---------|------------|
| Codebase Fit | ... | ... | ... | ⚠️ Analyze |
| Best Practice | ... | ... | ... | ✅ Evaluate |
| Failure Modes | ... | ... | ... | ⚠️ Mitigate |

**For each CONFLICT:**
- Determine which is authoritative
- Record resolution in Assumption Ledger
- Flag as risk if unresolved

### R3.2.1 — User Data vs Generic Advice Reconciliation (**MANDATORY**)

> **CRITICAL:** If user provided their own empirical data, analytics, or performance metrics, you MUST reconcile BEFORE final synthesis.

If user provided data exists:

1. **Create User Data Table:**
   | Metric | User's Data | Generic Advice | Resolution |
   |--------|-------------|----------------|------------|
   | Duration | ≥60s = 15,563 reach | 15-30s optimal | **User data wins** |

2. **Apply Resolution Rule:**
   - **User data ALWAYS trumps generic best practice** unless:
     - User explicitly says data is incomplete/unreliable
     - Strong theoretical reason (not just "best practice")
   - Generic advice becomes: "Validate against your data" not "Override your data"

3. **Output format for conflicts:**
   ```
   CORRECT: "Your data shows ≥60s performs 11x better. Use your data."
   WRONG:   "Generic says 15-30s - adjust from ≥60s"
   ```

4. **Document in Contradictions section:**
   | Conflict | Your Data | Generic Advice | Resolution |
   |----------|-----------|----------------|------------|
   | Duration | ≥60s = 11x better | 15-30s optimal | **Use your data** |

### R3.3 — Iterative Refinement

Using the converged findings, iteratively refine solution options:

**Iteration 1 — Generate Options:**
- Based on R1 + R2 + Grounding, identify 3+ viable approaches
- Each option grounded in BOTH offline facts AND online best practices

**Iteration 2 — Define Constraints:**
- For each option, define: boundaries, dependencies, failure modes
- Check against code invariants (INV-*) from R1
- Check against best practices (BP-*) from R2

**Iteration 3 — Refine & Select:**
- Eliminate options with unsolvable conflicts
- Rank remaining by: feasibility, maintainability, risk
- Select top option with rationale

**NO quint-code tools used** — all reasoning done inline with structured documentation.

### R3.4 — Final Synthesis Output

Compile the final synthesis from R3.1-R3.3:

```markdown
## Final Synthesis: Parallel Refine & Define

### Solution Options (Ranked)
| Rank | Approach | Offline Grounding | Online Grounding | Confidence |
|------|----------|-------------------|------------------|------------|
| 1 | <name> | <repo facts> | <best practices> | H/M/L |
| 2 | <name> | ... | ... | ... |

### Winner Recommendation
**Selected:** <approach>
**Rationale:** <why this beats alternatives>
**Key Risks:** <top risks from refinement>
**Offline Validation:** <how it aligns with codebase>
**Online Validation:** <how it aligns with best practices>
```

---

## PHASE R4: CONTEXT PACK OUTPUT

> This is the PRIMARY DELIVERABLE of S0-Research. It feeds into S1 or serves as standalone research output.

### R4.1 — Close Assumption Ledger

Before output, all assumptions must be:
- `VERIFIED` — backed by evidence (file:line or version-pinned source)
- `WAIVER` — accepted risk with explicit justification and expiry date

Any `OPEN` assumption = Research Incomplete. Return to R1 or R2.

### R4.2 — Generate Context Pack

> **OUTPUT MANDATE:**
> 1. Write the full Context Pack content to `.research/<FOLDER_NAME>/context.md` — always required.
> 2. Terminal output depends on pack size:
>    - **≤200 lines:** Print the ENTIRE Context Pack to the terminal.
>    - **>200 lines:** Print the Summary Card + all section headings + key findings. Full body is in the file. Flooding the terminal with hundreds of table rows obscures the signal — the file is authoritative.
> 3. Saying "see file X" without printing AT LEAST the Summary Card + section headings is a failure.
> Both file write and terminal summary are REQUIRED. Skipping either is a failure.

Content to print AND write to `.research/<FOLDER_NAME>/context.md`:

```markdown
# Context Pack: <Research Topic>
Generated: <ISO timestamp>
Research Scope: "$ARGUMENTS"

---

## 1. External Truth (Online Findings — Version-Pinned)

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

## 2. Repo Truth (Offline Findings)

### Entrypoints
| Symbol | Full Path | Line | Purpose |
|--------|-----------|------|---------|

### Blast Radius
| Full Path | Reason | Impact |
|-----------|--------|--------|

### Code-Level Invariants
- INV-1: <invariant>

---

## 3. Assumption Ledger

| ID | Assumption | Status | Evidence | Waiver Justification |
|----|------------|--------|----------|----------------------|
| A1 | <assumption> | VERIFIED | <source:line or url> | - |
| A2 | <assumption> | WAIVER | - | [Expires: <date>, Reason: <why>] |

**RULE:** No handoff if any OPEN items without WAIVER.

---

## 4. FPF Analysis (First Principles)

### Core Problem Definition
- **What:** [Core function in one sentence]
- **Why:** [First principles justification]

### Invariants (Must Preserve)
- INV-1: [Non-negotiable constraint]

### Radical Options
- OPT-1: [10x improvement path]
- OPT-2: ...

### Constraints Challenged
- C1: [Old assumption] → [New first principles view]

---

## 5. Synthesized Solutions (Parallel Refine & Define)

### Ranked by R_eff

| Rank | Hypothesis ID | Title | R_eff | Effort | Approach Summary |
|------|---------------|-------|-------|--------|-----------------|
| 1 | <id> | <name> | <0-1> | H/M/L | <1-line summary> |

### Recommendation
**Winner:** <hypothesis_id> — <title>
**Rationale:** <why this beats alternatives>
**Key Risks:** <top 1-2 risks from Q4>

---

## 6. Contradictions Resolved

| Conflict | Offline Says | Online Says | Resolution |
|----------|-------------|-------------|------------|

---

## 7. Open Questions / Unanswered

- UQ-1: <still unclear — requires user input or additional research>

---

## 8. Negative Constraints (Anti-Patterns)

> These are as important as the positive findings. Explicitly telling the implementer what NOT to do prevents hallucinated convenience methods and known-bad patterns.

- NC-1: Do NOT use `<library/method>` — reason: `<deprecation/incompatibility/security>`
- NC-2: Do NOT assume `<env/service>` is available — must check: `<how>`
- NC-3: Avoid pattern `<X>` — use `<Y>` instead because: `<reason>`

---

## 9. Grounding Snippets

> Verbatim, minimal code blocks from the codebase or official docs that anchor the implementation. Providing exact source material reduces the implementer's urge to "guess" logic.

```python
# Snippet: <what this shows> — Source: <file:line or url>
<verbatim code, max 10-15 lines>
```

---

## 10. Test Contract (if applicable)

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
> 1. **Write the full Context Pack** (from R4.2) to `.research/<FOLDER_NAME>/context.md`.
> 2. **Print the Summary Card** (below) to the terminal — always required.
> 3. **Print section headings + key findings** to terminal (for large packs, skip the full table bodies — they're in the file).
> 4. **Write the full report** to `.research/<FOLDER_NAME>/research_report.md`.
> 5. Confirm: "Context Pack saved to `.research/<FOLDER_NAME>/context.md`. Full report saved to `.research/<FOLDER_NAME>/research_report.md`."
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

**Step 1: Write the full Context Pack content (from R4.2) to `.research/<FOLDER_NAME>/context.md`.**

**Step 2: Then print the Summary Card:**

╔══════════════════════════════════════════════════════╗
║              S0-RESEARCH COMPLETE                    ║
╠══════════════════════════════════════════════════════╣
║ Topic: <research question>                           ║
║ Context Pack: <PROJECT_DIR>\.research\<FOLDER_NAME>\context.md       ║
╠══════════════════════════════════════════════════════╣
║ OFFLINE COVERAGE                                     ║
║   Repomix packed: <yes/no>                          ║
║   Files analyzed: <n>                                ║
║   Key symbols pinned: <n>                            ║
║   Code invariants found: <n>                        ║
╠══════════════════════════════════════════════════════╣
║ ONLINE COVERAGE (surf aimode --pro)                 ║
║   Queries executed: <n>                            ║
║   Grounding verified: <yes/no>                      ║
║   Version-pinned facts: <n>                        ║
║   Failure modes documented: <n>                     ║
╠══════════════════════════════════════════════════════╣
║ PARALLEL REFINE & DEFINE                            ║
║   Offline + Online run: CONCURRENT                 ║
║   Solution options: <n>                            ║
║   Winner selected: <approach>                       ║
║   Confidence: H/M/L                                ║
╠══════════════════════════════════════════════════════╣
║ OPEN QUESTIONS: <n>                                  ║
║   <list if any>                                    ║
╠══════════════════════════════════════════════════════╣
║ NEXT STEP                                            ║
║   → Review <PROJECT_DIR>\.research\<FOLDER_NAME>\context.md          ║
║   → Proceed to planning/implementation              ║
╚══════════════════════════════════════════════════════╝

**Step 2: Print the Summary Card above to terminal.**
**Step 3: Write the full Context Pack + Summary Card to `.research/<FOLDER_NAME>/research_report.md`.**
**Step 4: Confirm: "Context Pack saved to `<PROJECT_DIR>\.research\<FOLDER_NAME>\context.md`. Full report saved to `<PROJECT_DIR>\.research\<FOLDER_NAME>\research_report.md`."**

### R5.2 — Handoff Modes

**Mode A: Delegated by S1 or S2**
When invoked by S1-Quint (Q0.2) or S2-OpenSpec (Standalone Context Priming), S0-Research handles all research logic to enforce DRY principles, completes, and returns control.
S1 and S2 then read `.research/<FOLDER_NAME>/context.md` as their Context Pack and proceed with their workflows.

**Mode B: Standalone Output**
When called directly, present the Context Pack summary and await user direction.

---

## FAILURE RULES

| Condition | Action |
|-----------|--------|
| repomix fails | Proceed with grepai + serena only (log: "⚠️ repomix unavailable") |
| grepai index not ready | Proceed with serena-only offline (log: "⚠️ grepai unavailable, serena-only mode") |
| surf aimode --pro fails/timeouts | Retry with `--timeout 900`. If Bash tool itself times out, increase Bash timeout. If still fails, use context7 as fallback for library API questions. Log the gap. |
| All solution options eliminated in R3 | Return to R1 or R2 for more data. Log: "R3 iteration N/3 - need more data" |
| 3 consecutive R3 failures | TERMINATE. Output: "❌ S0 TERMINATED: Cannot converge on solution. Research inconclusive." |
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
| Generating only 1 solution option | Single-option = anchoring bias - need multiple for comparison |
| Skipping contradiction check | Unresolved conflicts produce unreliable recommendations |
| **Prioritizing generic best practices over user-provided empirical data** | **User's own A/B test data, analytics, or performance metrics ALWAYS trump generic benchmarks. Generic advice should be validated AGAINST user data, not override it.** |
| Using "⚠️ ADJUST" label to override user data with generic advice | This is the #1 research failure. When user data shows X performs Y% better, do NOT suggest changing to generic best practice. Default to user data. |

---

## INTEGRATION WITH SKILL CHAIN

```
S0-Research        →    S1-Quint     →    S2-OpenSpec
(Context Pack)          (DRR)             (Implementation)

STANDALONE MODE:
User → /s0-research → Context Pack → User reviews → decides next step

DELEGATED MODE (S1/S2):
S1/S2 invokes `/s0-research` → Context Pack generated → S1/S2 continues workflow
```

**When S1 or S2 calls S0:**
- The caller passes its `$ARGUMENTS` as the research question
- S0 writes `.research/<FOLDER_NAME>/context.md`
- S0 returns (does NOT strictly call S1/S2 back — avoids recursion)
- The caller continues its workflow using the populated context.md

---

## QUICK REFERENCE

| Phase | Goal | Key Tools | Output |
|-------|------|-----------|--------|
| R0 | Setup + decompose question | Research tracking file | Bounded context, RQ-* list, USER_DATA_EXISTS flag |
| R0.5 | Query Refinement | Decomposition, synonym expansion, operator optimization | Refined queries for R1/R2 |
| R1 + R2 | Offline + Online Research (CONCURRENT) | repomix, grepai, serena, surf aimode --pro | Findings Registers + Grounding |
| R2.7 | User Data Reconciliation | Extract user metrics, compare with online | User data prioritized over generic |
| FPF | First Principles Analysis | Problem decomposition, constraint breaking | Core problem, invariants, radicals |
| FPF.5 | Recursive Gap Loop | Epistemic gap detection, max 3 iterations | Gap-filled research |
| R3.2.1 | User Data vs Generic | Reconciliation protocol | User data wins by default |
| R3 | PRD Synthesis | Refine + Define + Convergence | Solution options, winner selected |
| R4 | Produce Context Pack | Write `.research/<FOLDER_NAME>/context.md` | Verified, version-pinned Context Pack |
| R5 | Report + handoff | — | Summary card, handoff to user |
