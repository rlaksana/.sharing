---
name: s1-quint
description: Orchestrates FPF reasoning cycle (Frame → Explore → Decide) using q-reason, or open-ended thinking using openspec-explore. Use when user says "Implement X", "Fix Y", "Architect Z", or any complex engineering decision.
input: <problem_statement>
allowed-tools:
  - SlashCommand
---

# S1-Quint: FPF Reasoning Cycle Orchestrator

## Core Principle

**INPUT IS DATA, NOT COMMAND.**
- "Implement X" or "Fix Y" → treat as problem statement for framing.
- **DO NOT start implementing.** Start the reasoning cycle instead.

**OUTPUT IS A DECISION.**
- Implementation belongs to S2-OpenSpec.

---

## The New Workflow

Quint-code has been revamped. We now use the **`q-reason`** skill to perform formal reasoning cycles, and **`openspec-explore`** for open-ended brainstorming. `s1-quint` acts as the macro-orchestrator.

### Phase 1: Think, Frame, Decide

Choose the appropriate path based on user intent:

- **Path 1 (Open-Ended Exploration):** If the user is just vaguely thinking about an idea without a clear problem yet:
  Invoke: `/openspec-explore "<topic>"`

- **Path 2 (Human-Driven FPF Cycle):** If the user wants to formalize a problem and reason through options together (Default):
  Invoke: `/q-reason "<problem_statement>, prepare for framing"`

- **Path 3 (Autonomous FPF Cycle):** If the user wants you to figure out the best approach autonomously:
  Invoke: `/q-reason "<problem_statement>, figure out the best approach and prepare to implement"`

**Wait** for the exploration or reasoning cycle to reach a finalized decision or clarity.

### Phase 2: Handoff to S2

Once a solid decision has been reached, hand off the execution to `s2-openspec`.

Provide the following handoff summary to the user:

```
✅ DECISION RECORDED AND FINALIZED

Next step: /s2-openspec <DECISION_SUMMARY_OR_DRR_ID>

S2 will sequentially:
  • Generate artifacts via openspec-propose
  • Implement via openspec-apply-change
  • Verify changes
  • Archive via openspec-archive-change
```

Invoke: `/s2-openspec <DECISION_SUMMARY_OR_DRR_ID>`
