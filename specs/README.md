# `specs/` — Spec-Driven Development workspace

Each feature gets a folder `NNN-feature-slug/` containing three artifacts produced by the
SDD pipeline:

| File | Produced by | Contents |
|------|-------------|----------|
| `spec.md` | `/specify` → `op-spec-writer` | WHAT & WHY — testable requirements, no implementation |
| `plan.md` | `/plan` → `op-planner` | HOW — layers, files, decisions, test strategy |
| `tasks.md` | `/tasks` → `op-planner` | Ordered tasks mapped to agents + parallel groups |

`_templates/` holds the source-of-truth templates the agents fill in. Edit them to change
the structure of every future spec/plan/tasks file.

See [`docs/development/spec-driven-development.md`](../docs/development/spec-driven-development.md)
for the full methodology, and [`.claude/agents/`](../.claude/agents) for the agents.

> This folder is **not** the RSpec suite — that is `spec/` (singular).
