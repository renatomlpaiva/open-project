<!--
  TASKS — the executable breakdown. Filled in by `op-planner` via /tasks and
  consumed by /implement. Each task is small, names ONE agent, lists its files,
  its dependencies, and a parallel group. Tasks in the same group run concurrently.
  Status legend: [ ] pending  [~] in-progress  [x] done  [!] blocked
-->

# Tasks: <Feature title>

| | |
|---|---|
| **Plan** | ./plan.md |
| **Status** | not-started \| in-progress \| done |

## Parallelization

- Tasks with the **same `Group`** value have no interdependencies and run in parallel.
- A task only starts once everything in its `Depends` list is `[x]`.

## Task list

| ID | Status | Agent | Description | Files | Depends | Group | Done when |
|----|--------|-------|-------------|-------|---------|-------|-----------|
| T1 | [ ] | op-backend | Add migration + model changes | `db/migrate/...`, `app/models/...` | — | A | migration runs; model validations pass |
| T2 | [ ] | op-backend | Create/Update service + contract + policy | `app/services/...`, `app/contracts/...`, `app/policies/...` | T1 | B | service returns ServiceResult; contract validates |
| T3 | [ ] | op-api | v3 endpoint + representer | `lib/api/v3/...` | T2 | C | request spec green |
| T4 | [ ] | op-frontend | Stimulus controller + ViewComponent | `frontend/src/stimulus/...`, `app/components/...` | T2 | C | renders; eslint + erb_lint clean |
| T5 | [ ] | op-tester | Model/service/request/feature specs | `spec/...` | T2,T3,T4 | D | `bin/rspec` green; covers all acceptance criteria |
| T6 | [ ] | op-tester | Frontend unit specs | `frontend/src/...spec.ts` | T4 | D | `cd frontend && npm test` green |
| T7 | [ ] | op-reviewer | Lint + diff review vs spec | — | T5,T6 | E | rubocop/eslint/erb_lint clean; criteria met |

> Group C (T3, T4) runs in parallel; Group D (T5, T6) runs in parallel after C.
>
> Frontend tasks (`op-frontend`) must name the design-system tokens/components/theme they
> touch (see `docs/design-system.md`).

## Notes / decisions during implementation

- <Append anything the agents discover that changes the plan.>
