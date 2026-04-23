## Verification Tasks (Auto-Injected from DRR)

These tasks are generated from the DRR Constraints Bundle and Verification Evidence Required.

### V1: Unit Tests
- **Task:** Implement unit tests per Test Contract
- **Evidence Path:** `openspec/changes/$CHANGE_ID/evidence/unit-tests.log`
- **Pass Criteria:**
  - All tests PASS
  - Line coverage >= 80%
  - Branch coverage >= 70%
- **DRR Constraint Mapping:** C-F1, C-F2, C-F3

### V2: Integration Tests
- **Task:** Implement integration tests per Test Contract
- **Evidence Path:** `openspec/changes/$CHANGE_ID/evidence/integration-tests.log`
- **Pass Criteria:**
  - All tests PASS
  - Database transactions verified
  - API contracts validated
- **DRR Constraint Mapping:** C-F1, C-NF2

### V3: Coverage Verification
- **Task:** Generate coverage report
- **Evidence Path:** `openspec/changes/$CHANGE_ID/evidence/coverage.json`
- **Pass Criteria:**
  - Line coverage >= 80%
  - Branch coverage >= 70%
  - Function coverage >= 90%
- **DRR Constraint Mapping:** Test Contract thresholds

### V4: Constraint Validation
- **Task:** Verify all DRR constraints are satisfied
- **Evidence Path:** `openspec/changes/$CHANGE_ID/evidence/constraint-check.md`
- **Pass Criteria:**
  - Each C-* constraint verified with evidence
  - No drift from DRR Constraints Bundle
- **DRR Constraint Mapping:** ALL C-F* and C-NF*

### V5: Performance Verification
- **Task:** Run performance benchmarks
- **Evidence Path:** `openspec/changes/$CHANGE_ID/evidence/perf-results.json`
- **Pass Criteria:**
  - API response < 100ms at p95
  - Database query < 10ms at p99
- **DRR Constraint Mapping:** C-NF1

### V6: Security Scan
- **Task:** Run security linting and dependency check
- **Evidence Path:** `openspec/changes/$CHANGE_ID/evidence/security-scan.log`
- **Pass Criteria:**
  - No high/critical vulnerabilities
  - All inputs sanitized
  - Parameterized queries only
- **DRR Constraint Mapping:** C-NF2
