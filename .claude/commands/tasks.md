---
description: SDD step 3 — decompose the plan into agent-mapped, parallelizable tasks via op-planner
argument-hint: [feature-folder] (defaults to the most recent spec)
---

You are orchestrating step 3 of Spec-Driven Development (see
`docs/development/spec-driven-development.md`).

Target: **$ARGUMENTS**

Do this:

1. **Resolve the feature folder** (as in `/plan`: explicit `$ARGUMENTS` or the most recent
   `specs/NNN-*`). Confirm `plan.md` exists; if not, stop and tell the user to run `/plan`.
2. **Delegate to the subagent.** Use your Task tool to launch the **`op-planner`** subagent
   in **tasks mode**:
   > Mode: tasks. Feature folder: `specs/NNN-slug/`.
   > Read `plan.md` and `specs/_templates/tasks-template.md`. Decompose into the smallest
   > useful tasks. For each task set: the one owning agent (`op-backend`, `op-api`,
   > `op-frontend`, `op-tester`, `op-reviewer`), its files, Depends, a Group (same Group =
   > runs in parallel), and a done-when check. Include a tester task covering every
   > acceptance criterion and a final `op-reviewer` task. Write `specs/NNN-slug/tasks.md`.
3. **Report back** the task table summary: how many tasks, which agents, and the parallel
   groups. Tell the user to review `tasks.md`, then run `/implement`.
