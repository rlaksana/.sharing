#!/usr/bin/env node
/**
 * Normalize Change Name
 *
 * Converts any input name to lowercase kebab-case.
 * This ensures DRR-XXXX inputs become drr-xxxx before validation.
 *
 * Usage: node normalize-change-name.js "DRR-2026-02-13-test" -> "drr-2026-02-13-test"
 */

function normalizeChangeName(name) {
    if (!name || typeof name !== 'string') {
        return { success: false, error: 'Name is required' };
    }

    // Normalize to lowercase
    const normalized = name.toLowerCase();

    return {
        success: true,
        original: name,
        normalized: normalized,
        changed: name !== normalized
    };
}

// CLI usage
if (require.main === module) {
    const input = process.argv[2];
    const result = normalizeChangeName(input);

    if (result.success) {
        console.log(result.normalized);
        process.exit(0);
    } else {
        console.error(result.error);
        process.exit(1);
    }
}

module.exports = { normalizeChangeName };
