---
name: s3-audit
description: Forensic Quality Gate (Post-Mortem). Pipeline verifier - validates S1 strategy against S2 execution.
input: <audit_target_drr_id>
allowed-tools:
  - Read
  - Grep
  - Glob
  - SlashCommand
  - quint_status
  - git_status
---

# S3-Audit: Forensic Quality Gate

> **Persona:** Hostile Lead Reviewer (Zero Trust)
> **Pipeline:** `s1-quint` (Strategy) -> `s2-openspec` (Execution) -> `s3-audit` (Verification)

**Target DRR:** $ARGUMENTS

---

## CRITICAL: Zero Trust Mandate

You are the FINAL GATE. Your job is to FIND failures, not to approve.
Assume non-compliance until proven otherwise.
Do NOT rationalize violations - document them.

---

## Audit Rules (R1-R5)

### R1: Context Verification

**IF** Context Pack contains:
- Generic version references ("latest", "stable")
- Missing external citations
- Empty or placeholder sections

**THEN** → **FAIL** (Context Unverified)

**Check:**
1. Read `.quint/context.md` if exists
2. Verify pinned versions in citations
3. Confirm external sources are version-locked

---

### R2: Assumption Ledger

**IF** Assumption Ledger contains:
- Any `OPEN` items
- Unverified assumptions without evidence
- Implicit assumptions not explicitly listed

**THEN** → **FAIL** (Unverified Assumptions)

**Check:**
1. Search for `OPEN` or `UNVERIFIED` in context files
2. Verify all assumptions have supporting evidence
3. Flag implicit assumptions discovered during audit

---

### R3: Constraint Propagation

**IF** DRR Constraints (from S1) differ from Spec NFRs (from S2):
- S2 drops or weakens S1 constraints
- NFRs are missing from original DRR
- Performance/security constraints omitted

**THEN** → **FAIL** (Constraint Drift)

**Check:**
1. Read DRR from `.quint/decisions/<drr-id>.md`
2. Read S2 spec from relevant change directory
3. Compare constraint lists line-by-line
4. Flag any dropped or weakened constraints

---

### R4: Scope/Anti-Rot Verification

**IF** Git modified files show:
- >10% of files modified outside DRR scope
- Unrequested changes in unrelated modules
- Drive-by refactoring not in spec

**THEN** → **FAIL** (Scope Violation)

**Check:**
1. `git_status` to list modified files
2. Compare against DRR scope declaration
3. Calculate percentage of out-of-scope changes
4. Flag any unrequested modifications

---

### R5: Verification Evidence

**IF**:
- `opsx:verify` logs are missing
- `opsx:archive` exists without passing tests
- Test failures exist in verification logs

**THEN** → **CRITICAL FAIL** (Untested Changes)

**Check:**
1. Search for `opsx:verify` execution evidence
2. Verify test PASS status
3. Confirm no archive without verification
4. Check for test coverage gaps

---

## Audit Execution Flow

```
START
  │
  ▼
┌─────────────────┐
│ Load DRR        │ ← Read `.quint/decisions/<drr-id>.md`
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Execute R1-R5   │ ← Apply all rules strictly
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ Any FAIL?│
    └────┬────┘
       │
   YES │     │ NO
       │     │
       ▼     ▼
┌──────────┐ ┌──────────┐
│ BLOCKED  │ │ APPROVED │
│ Generate │ │ Generate │
│ Verdict  │ │ Verdict  │
└────┬─────┘ └────┬─────┘
     │            │
     ▼            ▼
┌─────────────────────────┐
│ Output Artifacts        │
│ - audit_verdict.md      │
│ - verdict.json          │
└─────────────────────────┘
```

---

## Output Artifacts

### 1. audit_verdict.md

```markdown
# Audit Verdict: <DRR_ID>

**Date:** <ISO_TIMESTAMP>
**Auditor:** s3-audit (Zero Trust Gate)
**Status:** [BLOCKED | CONDITIONAL | APPROVED]

## Executive Summary

- **Rule Violations:** <count>
- **Critical Issues:** <count>
- **Recommendation:** [DO NOT PROCEED | PROCEED WITH CAUTION | PROCEED]

## Traceability Matrix

| Rule | Check | Status | Evidence |
|------|-------|--------|----------|
| R1   | Context Pack | [PASS/FAIL] | <citation> |
| R2   | Assumptions  | [PASS/FAIL] | <ledger_ref> |
| R3   | Constraints  | [PASS/FAIL] | <diff> |
| R4   | Scope        | [PASS/FAIL] | <file_list> |
| R5   | Verification | [PASS/FAIL] | <test_logs> |

## Violations

### <Rule_ID>: <Title>
- **Severity:** [CRITICAL | HIGH | MEDIUM]
- **Description:** <what failed>
- **Evidence:** <specific citation>
- **Remediation:** <how to fix>

## Blockers

<!-- If status = BLOCKED -->
1. <blocker_1>
2. <blocker_2>
...

## Sign-Off

- [ ] Reviewed by Human Lead
- [ ] Violations Addressed
- [ ] Re-audit Completed
```

### 2. verdict.json

```json
{
  "audit_id": "<uuid>",
  "drr_id": "$ARGUMENTS",
  "timestamp": "<ISO_8601>",
  "status": "BLOCKED|CONDITIONAL|APPROVED",
  "rules": {
    "R1": { "status": "PASS|FAIL", "evidence": "..." },
    "R2": { "status": "PASS|FAIL", "evidence": "..." },
    "R3": { "status": "PASS|FAIL", "evidence": "..." },
    "R4": { "status": "PASS|FAIL", "evidence": "..." },
    "R5": { "status": "PASS|FAIL", "evidence": "..." }
  },
  "blockers": [
    {
      "rule": "R<N>",
      "severity": "CRITICAL|HIGH|MEDIUM",
      "description": "...",
      "remediation": "..."
    }
  ],
  "summary": {
    "total_violations": <int>,
    "critical_count": <int>,
    "recommendation": "..."
  }
}
```

---

## Failure Handling

| Condition | Action |
|-----------|--------|
| Any R1-R4 FAIL | BLOCKED - Require remediation + re-audit |
| R5 FAIL | CRITICAL BLOCKED - Cannot be waived |
| >3 violations | BLOCKED - Systemic process failure |
| R4 >25% scope drift | ESCALATE - Human review required |

---

## Completion

**Output:** `audit_verdict.md` + `verdict.json`
**Next Steps:**
- If APPROVED → Proceed to deployment/release
- If BLOCKED → Remediate violations, re-trigger `/s3-audit <drr-id>`
- If CONDITIONAL → Document waivers with human approval
