---
description: SDD step 4 — execute tasks.md by dispatching each task to its mapped subagent (parallel where possible), then test and review
argument-hint: [feature-folder] (defaults to the most recent spec)
---

You are the **orchestrator** for step 4 of Spec-Driven Development (see
`docs/development/spec-driven-development.md`). Keep your own context small: hand each agent
only its task row plus pointers to `spec.md`/`plan.md` — do not paste large file bodies.

Target: **$ARGUMENTS**

Do this:

1. **Resolve the feature folder** (explicit `$ARGUMENTS` or the most recent `specs/NNN-*`).
   Read `tasks.md`. If it is missing, stop and tell the user to run `/tasks`.
2. **Execute by parallel group.** Process groups in order (A, B, C, …). A task may start
   only when every task in its `Depends` list is `[x]`. **Within a group, launch all of its
   agents concurrently** — issue the Task-tool calls in a single message so they run in
   parallel. Give each subagent exactly:
   > Implement task `T<n>` from `specs/NNN-slug/tasks.md`. Context: `spec.md`, `plan.md`.
   > Touch only the files listed for your task and stay inside your layer. Validate per your
   > instructions, then report files changed, decisions, and anything other tasks depend on.
3. **Update status** in `tasks.md` as you go: `[~]` when dispatched, `[x]` when the agent
   reports success and its done-when check passes, `[!]` if blocked (record why).
4. **Test, then review.** After the implementation groups, run the **`op-tester`** task(s),
   then the final **`op-reviewer`** task. If `op-reviewer` returns *changes-required*, route
   each finding to its owning agent (a fresh, scoped subagent call), then re-run the
   reviewer. Loop until *ready* or until you need a human decision.
5. **Stop and summarize.** Report what was implemented, the test results (verbatim
   pass/fail), and the reviewer verdict. **Do not commit or push** unless the user asks.

Guardrails: respect the layer boundaries (`op-backend` ≠ API ≠ frontend ≠ specs); never let
one agent edit another's files. If two ready tasks would edit the same file, serialize them.
