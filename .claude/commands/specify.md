---
description: SDD step 1 — turn a feature request into a testable spec via the op-spec-writer subagent
argument-hint: <feature description>
---

You are orchestrating step 1 of Spec-Driven Development (see
`docs/development/spec-driven-development.md`).

Feature request: **$ARGUMENTS**

Do this:

1. **Pick the spec id.** List existing feature folders with
   `ls -d specs/[0-9]*-* 2>/dev/null`. Take the highest `NNN`, add 1, zero-pad to 3
   digits (start at `001` if none). Build a kebab-case `slug` from the request (≤ 5 words).
2. **Create the folder** `specs/NNN-slug/`.
3. **Delegate to the subagent.** Use your Task tool to launch the **`op-spec-writer`**
   subagent with these instructions:
   > Write the specification for: "$ARGUMENTS".
   > Use the structure in `specs/_templates/spec-template.md`.
   > Save it to `specs/NNN-slug/spec.md` (set ID = NNN, Created = today).
   > Capture WHAT & WHY only — no implementation. Record ambiguities as Open questions.
   > Return the path, a short summary, and the open questions.
4. **Report back** the spec path and the open questions, and tell the user to review/edit
   `spec.md`, then run `/plan`. Do not start planning or coding.
