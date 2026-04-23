# S1/S2/S3 Evidence-First Workflow Regression Checklist

This checklist validates the evidence-first workflow implementation with constraint propagation and strict verification gating.

---

## Scenario 1: Context Pack Version Pinning Enforcement (R1)

**Test:** S1 rejects generic version references

**Setup:**
```markdown
# Context Pack with INVALID external references

## External Truth
| Library | Version | Source |
|---------|---------|--------|
| React | latest | https://react.dev |  <!-- INVALID -->
| Node | stable | https://nodejs.org | <!-- INVALID -->
```

**Expected Behavior:**
- [ ] S1 Q5 blocks with: "External references must be version-pinned"
- [ ] DRR cannot be recorded until fixed
- [ ] User must provide specific versions (e.g., "React 18.2.0")

**Pass Criteria:**
- Context Pack rejected with clear error message
- Cannot proceed to Q5 decision

---

## Scenario 2: Assumption Ledger OPEN Items (R2)

**Test:** S1 blocks DRR with OPEN assumptions

**Setup:**
```markdown
## Assumption Ledger
| ID | Assumption | Status | Evidence |
|----|------------|--------|----------|
| A1 | Redis available | OPEN | - |  <!-- BLOCKS -->
| A2 | Node >= 18 | VERIFIED | package.json |
```

**Expected Behavior:**
- [ ] S1 Q5 checklist shows: "Assumption Ledger: OPEN items: A1"
- [ ] User must either:
  - Verify A1 with evidence, OR
  - Add WAIVER with justification

**Pass Criteria:**
- DRR recording blocked until A1 resolved
- After adding WAIVER: "[WAIVER: Local dev only]" → DRR allowed

---

## Scenario 3: S2 Constraint Propagation (R3)

**Test:** DRR constraints appear in OpenSpec artifacts

**Setup:**
```markdown
# DRR Constraints Bundle
- C-NF1: API response < 100ms at p95
- C-F1: All emails validated per RFC 5322
```

**Expected Behavior:**
- [ ] After `/opsx:ff`, `spec.md` contains NFRs section with C-NF1
- [ ] `tasks.md` contains verification tasks for C-F1 and C-NF1
- [ ] Constraint ID preserved (C-NF1, C-F1) for traceability

**Pass Criteria:**
```markdown
# spec.md NFRs
## C-NF1: Performance
API response must be < 100ms at p95 under 1000 RPS.
```

---

## Scenario 4: Archive Gating Without Verification (R5)

**Test:** S2 blocks archive without PASS evidence

**Setup:**
- Change implementation complete
- Tests exist but verification_result.json missing

**Expected Behavior:**
- [ ] STATE 6 (Archive) pre-check fails
- [ ] Report: "Archive blocked: verification_result.json missing"
- [ ] No archive action taken

**Pass Criteria:**
- Archive explicitly blocked
- Clear message about missing evidence

**Then:**
- Run `/opsx:verify` → generates verification_result.json with "status": "FAIL"

**Expected:**
- [ ] Archive still blocked: "status != PASS"
- [ ] Must fix issues and re-verify

---

## Scenario 5: S3 Scope Drift Detection (R4)

**Test:** S3 calculates scope drift and escalates

**Setup:**
```markdown
# DRR Scope Boundaries
IN-SCOPE: src/api/users.ts, src/db/user-model.ts
OUT-OF-SCOPE: src/auth/*, src/ui/*
```

**Git Status:**
```
M src/api/users.ts          (in-scope)
M src/db/user-model.ts      (in-scope)
M src/auth/middleware.ts    (out-of-scope - not incidental)
M src/ui/components/Button.tsx  (out-of-scope - not incidental)
M tests/api/users.test.ts   (incidental - excluded)
```

**Calculation:**
- Total modified: 5 files
- Out-of-scope: 2 files (src/auth, src/ui)
- Drift: 2/5 = 40%

**Expected Behavior:**
- [ ] S3 R4 calculates 40% scope drift
- [ ] Exceeds 25% threshold → Status: ESCALATE
- [ ] verdict.json: `"status": "ESCALATE"`
- [ ] audit_verdict.md: "Scope drift exceeds 25% threshold. Human review required."

**Pass Criteria:**
- ESCALATE status generated
- Human intervention required
- Cannot proceed without explicit override

---

## Scenario 6: S3 R5 Critical Failure (Cannot Waive)

**Test:** S3 blocks on missing verification evidence

**Setup:**
- All other checks pass
- verification_result.json exists but contains: `"status": "FAIL"`

**Expected Behavior:**
- [ ] R5 status: CRITICAL FAIL
- [ ] verdict.json: `"status": "BLOCKED"`
- [ ] audit_verdict.md: "CRITICAL: Verification failed. Cannot proceed."

**Pass Criteria:**
- BLOCKED status despite other rules passing
- No waiver option for R5 failure
- Must re-run verification with PASS status

---

## Scenario 7: End-to-End Happy Path

**Test:** Complete workflow with all gates passing

**Steps:**
1. `/s1-quint "Implement user API"`
2. S1 generates Context Pack with version-pinned refs
3. S1 closes Assumption Ledger (all VERIFIED)
4. User approves at Q5
5. S1 records DRR with Constraints Bundle
6. `/s2-openspec drr-001`
7. S2 propagates constraints to spec/tasks
8. S2 runs implementation
9. S2 verifies → generates PASS evidence
10. S2 archives successfully
11. `/s3-audit drr-001`
12. S3 verifies R1-R5 all PASS
13. S3 outputs APPROVED verdict

**Expected:**
- [ ] All checkpoints complete
- [ ] verification_result.json: `"status": "PASS"`
- [ ] verdict.json: `"status": "APPROVED"`
- [ ] All artifacts at canonical paths

---

## Quick Reference: Rule Severity

| Rule | Severity | Waivable | Auto-Fixable |
|------|----------|----------|--------------|
| R1 | HIGH | No (must fix refs) | No |
| R2 | HIGH | Partial (WAIVER allowed) | No |
| R3 | HIGH | No | No |
| R4 | MEDIUM | Yes (if ≤25%) | No |
| **R5** | **CRITICAL** | **NEVER** | No |

---

## Evidence File Locations (Canonical Paths)

```
.quint/
├── context.md                    # S1 Context Pack
└── decisions/
    └── drr-<id>.md              # S1 DRR with Constraints Bundle

openspec/changes/<id>/
├── spec.md                       # S2 propagated constraints
├── tasks.md                      # S2 verification tasks
├── verify.log                    # S2 verification output
├── verification_result.json      # S2 structured result
└── evidence/
    ├── unit-tests.log
    ├── integration-tests.log
    ├── coverage.json
    ├── constraint-check.md
    ├── perf-results.json
    └── security-scan.log

openspec/changes/<id>/           # S3 output
├── audit_verdict.md
└── verdict.json
```
