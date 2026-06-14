---
description: SDD step 2 — turn a spec into a technical plan via the op-planner subagent
argument-hint: [feature-folder] (defaults to the most recent spec)
---

You are orchestrating step 2 of Spec-Driven Development (see
`docs/development/spec-driven-development.md`).

Target: **$ARGUMENTS**

Do this:

1. **Resolve the feature folder.** If `$ARGUMENTS` names a folder under `specs/`, use it.
   Otherwise pick the most recently modified `specs/NNN-*` folder
   (`ls -dt specs/[0-9]*-* | head -1`). Confirm `spec.md` exists; if not, stop and tell the
   user to run `/specify` first.
2. **Check open questions.** If `spec.md` still has unanswered *Open questions*, surface
   them and ask the user to resolve them before planning (a wrong plan is expensive).
3. **Delegate to the subagent.** Use your Task tool to launch the **`op-planner`** subagent
   in **plan mode**:
   > Mode: plan. Feature folder: `specs/NNN-slug/`.
   > Read `spec.md` and `specs/_templates/plan-template.md`. Explore the relevant
   > OpenProject code and write `specs/NNN-slug/plan.md`: affected layers, data model &
   > migrations, services/contracts, API/representers, frontend, permissions, i18n, test
   > strategy, risks, and a file-level change map. Return key decisions, risks, and the path.
4. **Report back** the plan path and a digest of decisions/risks. Tell the user to review
   `plan.md`, then run `/tasks`. Do not write code.
