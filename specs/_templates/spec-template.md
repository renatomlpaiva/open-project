<!--
  SPEC — the WHAT and WHY of a feature. NO implementation details (no file names,
  no class names, no framework choices). Filled in by the `op-spec-writer` agent
  via /specify. Keep it testable: every requirement should be verifiable.
-->

# Spec: <Feature title>

| | |
|---|---|
| **ID** | NNN |
| **Status** | draft \| approved \| in-progress \| done |
| **Created** | YYYY-MM-DD |
| **Work package** | #____ (if any) |

## Problem / motivation

<What user/business problem does this solve? Why now? 2–4 sentences.>

## User scenarios

Written as Given / When / Then so they map directly to acceptance tests.

1. **<Scenario name>**
   - **Given** <starting state>
   - **When** <action>
   - **Then** <observable outcome>

2. ...

## Functional requirements

Numbered, atomic, testable. Use MUST / SHOULD / MAY.

- **FR-1** The system MUST ...
- **FR-2** The system MUST ...
- **FR-3** The system SHOULD ...

## Out of scope

- <Explicitly excluded things, to prevent scope creep.>

## Edge cases & error handling

- <Empty/invalid input, permission denied, concurrency, large data, i18n, ...>

## Acceptance criteria

The feature is "done" when:

- [ ] <Criterion tied to FR-1 and a user scenario>
- [ ] <Criterion ...>

## Open questions

- [ ] <Anything ambiguous that needs a human decision before /plan>
