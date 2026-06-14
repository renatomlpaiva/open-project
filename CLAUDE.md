# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This branch (`sdd-toolkit`) is a **portable Spec-Driven Development (SDD) toolkit for Claude
Code** — a set of subagent and slash-command definitions plus templates that drive feature
development through a multi-agent pipeline. It is **not** an application: there is no build,
no test runner, and no package manifest. The tracked content is entirely Markdown:

```
.claude/agents/      7 specialized subagents (one Markdown file each, YAML frontmatter)
.claude/commands/    4 slash commands: /specify /plan /tasks /implement
specs/_templates/    spec-template.md, plan-template.md, tasks-template.md
specs/README.md      explains the specs/ feature workspace
docs/development/spec-driven-development.md   the methodology (read this first)
docs/design-system.md   the canonical UI standard the op-frontend agent builds to
```

> **Origin & host dependency:** this toolkit was extracted (as an orphan branch) from an
> **OpenProject** fork. The agents and templates reference OpenProject's architecture and
> paths (`app/services`, `app/contracts`, `app/policies`, `lib/api/v3`, `app/components`,
> `frontend/src/stimulus`, …) and an `AGENTS.md` that exist in the host app, **not on this
> isolated branch**. The toolkit is meant to be dropped into that host repo's working tree;
> in-branch links to `../../AGENTS.md` are intentionally dangling here.

## Big-picture architecture

The whole point is **token efficiency through small contexts**. Understanding it means
reading the methodology doc plus several agent files together; the key ideas:

- **A pipeline of thin commands over scoped subagents.** Each `/command` in
  `.claude/commands/` is a short orchestration prompt that prepares inputs and **delegates
  to one subagent** via the Task tool. The expensive thinking (codebase exploration, code
  edits) happens *inside* the subagent with throwaway context; only a distilled artifact
  returns to the orchestrator.

  ```
  /specify → op-spec-writer → specs/NNN-slug/spec.md   (WHAT & WHY)
  /plan    → op-planner      → specs/NNN-slug/plan.md   (HOW: layers, files, decisions)
  /tasks   → op-planner      → specs/NNN-slug/tasks.md  (tasks mapped to agents + groups)
  /implement → orchestrator dispatches each task to its agent, then tester, then reviewer
  ```

- **Each subagent owns one layer and only that layer.** Scope boundaries mirror the host
  app's architecture so an agent never loads code it won't touch:

  | Agent | Owns | Tools |
  |-------|------|-------|
  | `op-spec-writer` | writes `specs/**` (requirements only) | read + write |
  | `op-planner` | explores repo → writes `plan.md` / `tasks.md` | read + write |
  | `op-backend` | models, services (`ServiceResult`), contracts, policies, migrations | read/edit + bash |
  | `op-api` | Grape v3 endpoints + roar representers | read/edit + bash |
  | `op-frontend` | UI built to **`docs/design-system.md`** (tokens, light/dark, motion); host stack maps to it | read/edit + bash |
  | `op-tester` | RSpec + Vitest; covers every acceptance criterion | read/edit + bash |
  | `op-reviewer` | runs linters, reviews the diff (read-only) | read + bash |

  `op-frontend` additionally enforces the **design system** (`docs/design-system.md`): UI is
  built from its tokens/themes/components, and `op-reviewer` rejects hard-coded colors or a
  missing light/dark mode. On a non-Tailwind host the design-system *intent* is mapped onto
  the host's UI system (e.g. Primer ViewComponents for OpenProject).

- **`/implement` parallelizes.** It reads `tasks.md` and runs tasks of the same `Group`
  concurrently (multiple Task calls in one message), respecting `Depends`. This is where the
  speed win comes from; the file-level scoping is what keeps it safe (no two agents edit the
  same file).

- **`specs/_templates/` is the source of truth for artifact shape.** Agents fill these in;
  editing a template changes the structure of every future spec/plan/tasks file.

The full rationale, walkthrough, and the agent boundaries are in
[`docs/development/spec-driven-development.md`](docs/development/spec-driven-development.md).

## Editing conventions

This repo *is* its own configuration, so edits are almost always to the agent/command files.

- **Subagents** (`.claude/agents/<name>.md`) — YAML frontmatter then a focused system prompt:
  ```yaml
  ---
  name: op-something          # must match the filename
  description: when to use it # the orchestrator routes work using this line
  tools: Read, Edit, Bash     # restrict to the minimum the agent needs
  model: sonnet               # cheap model for mechanical work; raise if needed
  ---
  ```
  Keep each prompt **small and scoped**: state what the agent may touch, what it must *not*
  touch, the patterns to follow, what to read for context (point to docs, don't duplicate
  them), how to validate, and a concise output contract. Adding a layer = add an agent here
  *and* list it in `tasks-template.md` and the `op-planner` agent so `/tasks` can map to it.

- **Slash commands** (`.claude/commands/<name>.md`) — frontmatter (`description`,
  `argument-hint`) then an orchestration prompt that uses `$ARGUMENTS` and delegates to a
  subagent via the Task tool. Commands stay thin — no heavy work in the orchestrator.

- **Keep the small-context invariant.** The toolkit's value collapses if agents are given
  broad scope or commands stop delegating. Don't merge agents or inline large file bodies
  into outputs.

## Validating changes

There is no test/build step. After editing, sanity-check the frontmatter and structure:

```bash
# every agent has name + model; every command has a description
for f in .claude/agents/*.md;   do grep -q '^name:' "$f" && grep -q '^model:' "$f" || echo "FIX $f"; done
for f in .claude/commands/*.md; do grep -q '^description:' "$f" || echo "FIX $f"; done

# list what's installed
ls .claude/agents .claude/commands
```

The real "test" is running the pipeline (`/specify → /plan → /tasks → /implement`) inside a
host app repo and confirming each command launches the intended subagent and writes the
expected artifact under `specs/NNN-slug/`.

## Git context

This is an **orphan branch** (`sdd-toolkit`) with its own history, isolated from the host
application branches (`main`, `feat/*`). Keep it that way: commit only SDD files here; do
not pull application code onto this branch.
