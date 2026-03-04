# S2-OpenSpec Scripts

Helper scripts for the s2-openspec skill.

## normalize-change-name.js

Normalizes change names to lowercase kebab-case.

### Usage

```bash
node normalize-change-name.js "DRR-2026-02-13-test"
# Output: drr-2026-02-13-test
```

### Purpose

OpenSpec CLI requires lowercase kebab-case names. This script converts uppercase
prefixes (like DRR) to lowercase before validation, preventing errors.

### Integration

Called automatically by s2-openspec skill during Pre-Flight phase.
