# Claude Skills Repository

FPF-powered reasoning skills and OpenSpec execution workflows for Claude Code.

---

## Quick Start

```bash
# This repo has no build step — skills are loaded by Claude Code
# from .claude/skills/ and .claude/commands/ directories

# Validate skill syntax (read-only check)
head -20 s1-quint/SKILL.md s2-openspec/SKILL.md
```

---

## Repository Structure

| Path | Purpose |
|------|---------|
| `s1-quint/` | FPF Reasoning Kernel (Q0-Q5 phases). `/s1-quint` skill. |
| `s2-openspec/` | OpenSpec State Machine (opsx commands). `/s2-openspec` skill. |
| `s3-audit/` | Forensic Quality Gate. `/s3-audit` skill. |
| `.claude/skills/` | Skill packages (loaded by Claude Code CLI) |
| `.claude/commands/opsx/` | Slash command definitions (`/opsx:*`) |
| `openspec/` | Legacy OpenSpec workspace (changes/, specs/) |
| `shared-core.md` | Portable definitions imported by s1/s2 skills |

---

## Skill Development Workflow

1. **Edit** SKILL.md in respective skill directory (s1-quint/, s2-openspec/, s3-audit/)
2. **Update** templates/ if workflow artifacts change
3. **Sync** to .claude/skills/ if structure changes (manually mirror)
4. **Commit** with conventional prefix: `feat:`, `fix:`, `refactor:`, `chore:`

---

## Key Conventions

| Concept | Definition |
|---------|------------|
| **Skill** | High-level capability that orchestrates multi-step workflows |
| **Command** | Individual slash action for specific tasks |
| **Template** | Reusable artifact template (markdown, YAML) in templates/ |
| **S1/S2/S3** | Pipeline stages: Strategy → Execution → Audit |

**Naming:**
- Skills: `kebab-case/` directories under .claude/skills/
- Commands: Flat files under .claude/commands/opsx/
- Templates: Mirror artifact type (drr.md, context.md, etc.)

---

## Dependencies

- **Global CLAUDE.md**: Base operator mode at `~/.claude/CLAUDE.md`
- **Shared Core**: Import shared-core.md for cross-skill term definitions
- **Claude Code**: Skills loaded via .claude/ directory convention

---

## Gotchas

- **No automated tests** — Skills are validated by manual inspection
- **Skill/Command split** — Skills orchestrate; commands execute specific actions
- **Template drift** — Keep templates/ in sync with SKILL.md references
- **Serena index** — .serena/ is tool cache (gitignored)
- **Mirror manually** — Changes to s*/SKILL.md may need sync to .claude/skills/
