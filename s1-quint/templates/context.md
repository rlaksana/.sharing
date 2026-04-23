# Context Pack: <Change_Name>

**Generated:** <ISO_TIMESTAMP>
**Project:** <project_name>
**DRR Reference:** <drr-id> (to be filled after Q5)

---

## 1. Repo Truth (Code Facts)

### Entrypoints
| File | Symbol | Line | Purpose |
|------|--------|------|---------|
| `src/api/routes.ts` | `createUserHandler` | 45 | POST /users endpoint |
| `src/db/models.ts` | `UserModel` | 12 | User entity definition |

### Blast Radius
| File | Reason |
|------|--------|
| `src/api/routes.ts` | Direct modification |
| `src/api/validators.ts` | Validation logic affected |
| `tests/api/user.test.ts` | Tests for modified endpoint |

### Invariants (Code-level)
- `INV-1`: All API responses must include `requestId` header
- `INV-2`: Database transactions must use `withTransaction()` wrapper
- `INV-3`: No direct `console.log` — use structured logger only

---

## 2. External Truth (Version-Pinned)

| Library/Doc | Version | Source | Date Accessed |
|-------------|---------|--------|---------------|
| React | 18.2.0 | https://react.dev | 2024-01-15 |
| Express.js | 4.18.2 | https://expressjs.com/en/4x/api.html | 2024-01-15 |
| Node.js | 20.11.0 LTS | https://nodejs.org/docs/latest-v20.x/api/ | 2024-01-15 |
| TypeScript | 5.3.3 | https://www.typescriptlang.org/docs/handbook/intro.html | 2024-01-15 |

**NO GENERIC REFERENCES ALLOWED:**
- ❌ "Latest React docs"
- ❌ "Node stable"
- ❌ "Express current version"
- ✅ "React 18.2.0 (react.dev, 2024-01-15)"
- ✅ "commit a1b2c3d (repo, 2024-01-15)"

---

## 3. Assumption Ledger

| ID | Assumption | Status | Evidence | Waiver Justification |
|----|------------|--------|----------|----------------------|
| A1 | User has Node.js >= 18 | VERIFIED | `package.json#engines.node` | - |
| A2 | PostgreSQL is running on localhost:5432 | VERIFIED | `docker-compose.yml` service definition | - |
| A3 | Redis cache available | VERIFIED | `src/cache/redis.ts` connection check | - |
| A4 | Feature flag service accessible | WAIVER | - | Dev-only feature, production uses static config |

**STATUS VALUES:** `OPEN` | `VERIFIED` | `WAIVER`

**RULE:** No DRR if any `OPEN` items without `WAIVER`.

---

## 4. Test Contract / Definition of Done

### Required Tests
- [ ] **Unit tests:** `src/api/routes.ts`, `src/db/models.ts`
- [ ] **Integration tests:** POST /users flow, database transaction handling
- [ ] **Contract tests:** API response schema validation

### Anti-Flake Rules
- [ ] No `setTimeout` in tests without explicit reason and maximum duration
- [ ] No random data without seeded RNG (`faker.seed(12345)`)
- [ ] No network calls without mocks (use `nock` or `msw`)
- [ ] No file system operations without temp directories (`tmp` package)
- [ ] No database state dependencies — each test creates own fixtures

### Coverage Thresholds
- Line coverage: >= 80%
- Branch coverage: >= 70%
- Function coverage: >= 90%

### Performance Benchmarks
- API response time: < 100ms (p95)
- Database query time: < 10ms (p99)

---

## 5. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking API change | Low | High | Versioned routes, contract tests |
| DB migration failure | Medium | High | Transaction rollback, dry-run tests |

---

## 6. References

- Related DRRs: `.quint/decisions/`
- Change artifacts: `openspec/changes/<change-id>/`
