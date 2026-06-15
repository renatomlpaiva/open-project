<!--
  TASKS — the executable breakdown. Filled in by `op-planner` via /tasks and
  consumed by /implement. Each task is small, names ONE agent, lists its files,
  its dependencies, and a parallel group. Tasks in the same group run concurrently.
  Status legend: [ ] pending  [~] in-progress  [x] done  [!] blocked
-->

# Tasks: Filter projects list by subtitle

| | |
|---|---|
| **Plan** | ./plan.md |
| **Spec** | ./spec.md |
| **Status** | not-started |

## Parallelization

- Tasks with the **same `Group`** value have no interdependencies and run in parallel.
- A task only starts once everything in its `Depends` list is `[x]`.

## Environment (REQUIRED for every agent)

Every Ruby / rspec / rubocop / i18n-tasks command MUST be prefixed with the
following in the same shell invocation (rbenv shim + git shim on PATH, Spring
disabled):

```bash
export PATH="$HOME/.rbenv/versions/4.0.2/bin:/Users/renatomdelpaiva/Documents/dev/openproject-dev/tmp/gitshim:$PATH"; export DISABLE_SPRING=1
```

## Critical gotcha (from plan §Risks)

**The FRONTEND ALLOWLIST is the easy-to-miss step.** Registering the filter on
`ProjectQuery` (T1) is **not** sufficient for the UI — `Projects::ProjectsFiltersComponent#allowed_filter?`
uses an *explicit* allowlist (T2). Skipping T2 passes all API/backend tests but
silently omits the filter from the UI (breaks FR-4 / scenario 3). The feature
spec (T5) guards this.

## Task list

| ID | Status | Agent | Description | Files | Depends | Group | Done when |
|----|--------|-------|-------------|-------|---------|-------|-----------|
| T1 | [ ] | op-backend | Add `SubtitleFilter` query class (near-copy of `name_filter.rb`) and register it on `ProjectQuery` | `app/models/queries/projects/filters/subtitle_filter.rb` (add), `app/models/queries/projects.rb` (edit) | — | A | new file is a literal mirror of `name_filter.rb` with `projects.name`→`projects.subtitle`, `self.key :subtitle`, the `human_name` override **dropped**, and `#sql_value` kept verbatim; `filter Filters::SubtitleFilter` registered near `NameFilter`; `bundle exec rubocop app/models/queries/projects/filters/subtitle_filter.rb app/models/queries/projects.rb` clean; `ProjectQuery.new.available_filters` (or a `bin/rails runner`) shows a `:subtitle` filter |
| T2 | [ ] | op-frontend | Add `Queries::Projects::Filters::SubtitleFilter` to the UI allowlist | `app/components/projects/projects_filters_component.rb` (edit) | T1 | B | `Queries::Projects::Filters::SubtitleFilter` appended to the `allowlist` array in `#allowed_filter?`, alphabetically near `NameAndIdentifierFilter`; `bundle exec rubocop app/components/projects/projects_filters_component.rb` clean; constant resolves (no `NameError`) |
| T3 | [ ] | op-tester | Filter unit spec mirroring `name_filter_spec.rb` | `spec/models/queries/projects/filters/subtitle_filter_spec.rb` (add) | T1 | C | mirrors `name_filter_spec.rb`: `it_behaves_like "basic query filter"` with `class_key :subtitle`, `human_name "Subtitle"`, `type :string`, `allowed_values` nil; `#apply_to`/SQL assertions for operators `= ! ~ !~` (and `**`) against `LOWER(projects.subtitle)`; asserts no-subtitle (NULL) excluded from `~` and literal `%`/`_` handling; covers FR-1/2/3/9/10 + AC7/AC8; `bin/rspec spec/models/queries/projects/filters/subtitle_filter_spec.rb` green |
| T4 | [ ] | op-tester | API v3 request-spec context for subtitle filtering | `spec/requests/api/v3/projects/index_resource_spec.rb` (edit) | T1 | C | adds a "filtering by subtitle" context using `filters = [{ subtitle: { operator: "~", values: ["alpha"] } }]`; asserts (a) only matching+visible projects returned, (b) empty collection when none match, (c) a matching-but-non-visible project is excluded; covers FR-5/6/7/8 + AC3/AC4/AC5/AC6 (scenarios 2,4,6,7); `bin/rspec spec/requests/api/v3/projects/index_resource_spec.rb` green |
| T5 | [ ] | op-tester | Projects-list feature (UI) spec scenario | `spec/features/projects/lists/filters_spec.rb` (edit) | T1, T2 | D | adds a Capybara/Cuprite scenario: open the filter dropdown and assert **"Subtitle" is offered** (FR-4 / scenario 3 — guards the allowlist gotcha), apply a "contains" value and assert only matching **visible** projects are listed, including a mixed-case match (case-insensitive); covers AC1/AC2/AC4 (scenarios 1,3,5); `bin/rspec spec/features/projects/lists/filters_spec.rb` green |
| T6 | [ ] | op-reviewer | Final lint + diff review vs spec/plan | — (reviews T1–T5 diff) | T3, T4, T5 | E | `bundle exec rubocop` clean on all changed `.rb` files; `bundle exec i18n-tasks unused`/`missing` confirm **no new/orphaned key** (label reuses `activerecord.attributes.project.subtitle`); diff matches plan's file-level change map (no API/migration/locale changes); all 8 acceptance criteria traced to a passing test |

> Group C (T3, T4) runs in parallel after T1. T5 (Group D) needs both T1 and T2
> (the allowlist) so the "Subtitle" dropdown assertion can pass. T6 (Group E) is
> the final gate after all specs (T3, T4, T5) are green.

## Acceptance-criteria → task trace

| AC | Requirement(s) | Covered by |
|----|----------------|-----------|
| AC1 contains, case-insensitive | FR-1, FR-2, FR-3 | T3 (unit) + T5 (feature) |
| AC2 offered in UI, translatable | FR-4 | T2 (allowlist) + T5 (feature) |
| AC3 usable via API v3, stable key | FR-5 | T4 (request) |
| AC4 UI/API parity | FR-6 | T4 (request) + T5 (feature) |
| AC5 visibility respected | FR-7 | T4 (request) |
| AC6 empty result, no error | FR-8 | T4 (request) |
| AC7 no-subtitle excluded from contains | FR-10 | T3 (unit) |
| AC8 operator set parity | FR-9 | T3 (unit) |

## Notes / decisions during implementation

- No `op-api` task: API exposure is automatic (the `filters=` param matches `self.key == :subtitle`). API behavior is verified by T4's request spec.
- No migration/service/contract/policy/representer/locale/Angular tasks — all out of scope per plan (column exists from feature 001; visibility enforced by the query base scope, not the filter; label reuses an existing locale key).
- <Append anything the agents discover that changes the plan.>
