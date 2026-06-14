# Spec-Driven Development (SDD) for OpenProject

A development workflow for this repository where **specifications drive the work** and
the work is executed by a set of **small, specialized subagents** instead of one large
agent. Each subagent gets a *narrow scope and a small context*, which makes the whole
pipeline faster and dramatically cheaper in tokens.

> TL;DR — You describe a feature once. The pipeline turns it into a spec, a technical
> plan, and a task list, then dispatches each task to the cheapest agent that can do it,
> running independent tasks in parallel.

## Why multi-agent (the token/speed argument)

A single agent that does everything has to keep the *entire* codebase context, the
requirements, the plan, and the diff in one growing window. That window is re-sent on
every step — expensive and slow.

SDD splits the work so that:

- **Heavy exploration happens inside a subagent and never leaves it.** The
  `op-planner` may read 40 files to write the plan, but only the distilled `plan.md`
  (a few KB) returns to the orchestrator. The orchestrator never pays for those 40 files.
- **Each implementation agent only loads its own layer.** `op-backend` knows
  `app/services`, `app/contracts`, `app/policies`; it does *not* load Angular, Grape, or
  ViewComponents. Smaller prompt = fewer tokens + less chance of touching the wrong layer.
- **Independent tasks run in parallel.** Two agents editing different layers at the same
  time finish in wall-clock time `max(a, b)` instead of `a + b`.
- **Cheaper models do the mechanical work.** Implementation/test/review agents default to
  `sonnet`; the orchestrator (you) stays on the stronger model for high-level reasoning.

## The pipeline

```
/specify  ──▶  specs/NNN-feature/spec.md     (WHAT & WHY — no implementation)
   │                       op-spec-writer
   ▼
/plan     ──▶  specs/NNN-feature/plan.md     (HOW — layers, files, decisions)
   │                       op-planner
   ▼
/tasks    ──▶  specs/NNN-feature/tasks.md    (ordered tasks → mapped to agents)
   │                       op-planner
   ▼
/implement ─▶  code + tests + review         (orchestrator dispatches subagents)
                op-backend · op-api · op-frontend · op-tester · op-reviewer
```

Each command is thin: it just prepares inputs and launches the right subagent. The
expensive thinking lives in the subagents, with throwaway context.

## The agents

| Agent | Scope (what it may touch) | Tools | Default model |
|-------|---------------------------|-------|---------------|
| `op-spec-writer` | `specs/**` only (writes the spec) | read + write | sonnet |
| `op-planner` | read-only repo exploration → `specs/**` | read + write | sonnet |
| `op-backend` | `app/models`, `app/services`, `app/contracts`, `app/policies`, `db/migrate`, `modules/*/app` | read/edit + bash | sonnet |
| `op-api` | `lib/api/v3/**` (Grape + roar representers) | read/edit + bash | sonnet |
| `op-frontend` | `frontend/src/stimulus`, `frontend/src/turbo`, `app/components`, `app/views`, `frontend/src/app` (legacy Angular) | read/edit + bash | sonnet |
| `op-tester` | `spec/**`, `modules/*/spec`, `frontend/src/**/*.spec.ts` | read/edit + bash | sonnet |
| `op-reviewer` | read-only; runs linters; reviews the diff | read + bash | sonnet |

Each agent's full instructions live in [`.claude/agents/`](../../.claude/agents). They all
defer to [`AGENTS.md`](../../AGENTS.md) for repo-wide conventions (architecture, commit
rules, lint/test commands) instead of duplicating them — keeping their prompts small.

### Why these boundaries

They mirror the real OpenProject architecture (see *Architecture (Big Picture)* in
[`AGENTS.md`](../../AGENTS.md)):

- Write paths go through **service objects + contracts + policies** → `op-backend`.
- The REST API is **Grape with roar HAL representers** in `lib/api/v3` → `op-api`.
- New UI is **Hotwire (Stimulus/Turbo) + Primer ViewComponents**; legacy SPA is **Angular
  custom elements** → `op-frontend`.
- Tests are **RSpec** (incl. Capybara/Cuprite features) and **Vitest** → `op-tester`.

## Directory layout

```
specs/
  _templates/            # source-of-truth templates the agents fill in
    spec-template.md
    plan-template.md
    tasks-template.md
  NNN-feature-slug/       # one folder per feature (NNN = zero-padded counter)
    spec.md
    plan.md
    tasks.md
.claude/
  agents/                 # the specialized subagents
  commands/               # /specify /plan /tasks /implement
```

## How to use it

```text
/specify   Allow watchers to mute notifications for a single work package
/plan                     # uses the spec just created (or pass a folder name)
/tasks                    # decomposes the plan into agent-mapped tasks
/implement                # executes the tasks, then tests, then review
```

Walkthrough:

1. **`/specify <feature description>`** — `op-spec-writer` creates
   `specs/NNN-slug/spec.md` from the template: problem, user scenarios
   (Given/When/Then), numbered testable requirements, out-of-scope, acceptance
   criteria, open questions. **No implementation details.** Review and edit it.
2. **`/plan`** — `op-planner` reads the spec, explores the relevant code, and writes
   `plan.md`: which layers/files change, data model & migrations, services/contracts,
   API/representer changes, frontend changes, permissions, i18n, and a test strategy.
3. **`/tasks`** — `op-planner` turns the plan into `tasks.md`: a numbered list where each
   task names the **agent** that will do it, its **dependencies**, a **parallel group**,
   the **files** it touches, and a **done-when** check.
4. **`/implement`** — the orchestrator reads `tasks.md` and dispatches each task to its
   mapped agent. Tasks in the same parallel group run concurrently; dependent tasks wait.
   After implementation it runs `op-tester`, then `op-reviewer`, and updates task statuses.

### Review gates

The pipeline pauses for you between phases (spec → plan → tasks) and before/after
`/implement`. Specs and plans are cheap to fix; bugs in code are not. Read the artifact,
edit it, then run the next command.

## Conventions the agents follow

- **Architecture & patterns:** *Architecture (Big Picture)* in [`AGENTS.md`](../../AGENTS.md).
- **Design system:** all UI follows [`docs/design-system.md`](../design-system.md) — tokens,
  light/dark, Inter/Bricolage fonts, Lucide icons, motion, and status badges. `op-frontend`
  builds to it and `op-reviewer` checks conformance.
- **Lint before done:** `bundle exec rubocop` / `bin/dirty-rubocop --uncommitted`,
  `cd frontend && npx eslint src/`, `erb_lint {files}`.
- **Tests:** `bin/rspec path/to/spec.rb:LINE`, `cd frontend && npm test`.
- **Commits:** subject < 72 chars, blank line, body; reference work packages.

## Customizing

- **Add an agent** — drop a new file in `.claude/agents/`; reference it from
  `tasks-template.md` and the `op-planner` agent so `/tasks` can map work to it.
- **Change models** — edit the `model:` field in any agent's frontmatter (e.g. raise
  `op-planner` to a stronger model, or drop `op-reviewer` to a cheaper one).
- **Tighten scope** — narrow the `tools:` list or the scope description in an agent to
  shrink its context further.
