# Shared Core Definitions

Portable definitions for s1-quint and s2-openspec skills. Intergrate this to your CLAUDE.md before using skills.

---

## Core Terms

| Term | Definition |
|------|------------|
| **$STDS** | Applicable standards: DDD, Clean Arch, CQRS, SOLID, project patterns |
| **$BASE** | Naive/obvious solution. Benchmark for measuring hypothesis value-add |
| **Archetypes** | Mandatory 3-Path Scoping: [Naive] (Simplest), [Standard] (Robust), [Lateral] (Out-of-Box) |
| **ROI** | Impact metric: `R_eff / Effort` (where Effort is Low/Med/High) |
| **Surgical_Scope** | Stay within bounded context. No scope creep. Every change traces to request |
| **R_eff** | Effective Reliability (0-1). Calculated, not estimated |
| **WLNK** | Weakest Link. R_eff = min(evidence_scores), never average |
| **DRR** | Design Rationale Record. Persisted decision with context and consequences |

---

## Execution Guardrails

### Think Before Coding
- State assumptions explicitly. If uncertain, STOP and ask.
- If multiple interpretations exist, present them — don't pick silently.
- If simpler approach exists, say so.

### Simplicity First
- No speculative features — only what was asked.
- No single-use abstractions — inline if used once.
- 200→50 check: If code could be 75% shorter, rewrite it.

### Surgical Changes
- Touch only what you must. Every changed line traces to the request.
- Don't "improve" adjacent code — no drive-by refactors.
- Remove only YOUR orphans — imports/vars YOUR changes made unused.

### Code Edit Safety (AntiRot)
- When patching code, preserve 3 lines of context above and below the change
- Never target single generic lines (e.g., `return`, `}`, `pass`, `else:`)
- If context is ambiguous, use explicit line ranges instead

### Research Protocol (MANDATORY)
- **Offline:** Ground context via ES/GrepAI/Serena.
- **Online:** Verify lib/API usage via docs/web. **NEVER** rely on internal training data for syntax/versions.

### Change Audit (Requested & Unrequested)
**A. Requested (Traceability):**
- **Completeness:** Did we implement *everything* asked?
- **Mapping:** Every user requirement must trace to a specific line change.
- **Verification:** If user asked for X, where is the test for X?

**B. Unrequested (Anti-Rot):**
- **Zero Tolerance:** No "drive-by" refactoring. If it's not requested, DETACH.
- **No Optimization Creep:** Do not "optimize" adjacent code unless it's the Weakest Link.
- **Violation:** Changing `fmt`, `styles`, or `comments` outside the surgical scope is a critical failure.

### Goal-Driven Execution
Transform tasks to verifiable goals:
- "Add validation" → "Write tests for invalid inputs, make them pass"
- "Fix bug" → "Write reproducer test, make it pass"

---

## Anti-Patterns (FORBIDDEN)

| ❌ Don't | ✅ Do Instead |
|----------|---------------|
| Delete requirements to pass validation | Fix the implementation |
| Add "flexibility" not requested | Implement exactly what's asked |
| Refactor adjacent code | Touch only what's needed |
| Guess when unclear | STOP and ask |

---

## Architecture Principle

**Functional Core, Imperative Shell:**
- Pure functions (no side effects) → core business logic
- Side effects (I/O, state, external APIs) → isolated shell modules
- Core never calls shell; shell orchestrates core
