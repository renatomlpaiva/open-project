<!--
  TASKS — the executable breakdown. Filled in by `op-planner` via /tasks and
  consumed by /implement. Each task is small, names ONE agent, lists its files,
  its dependencies, and a parallel group. Tasks in the same group run concurrently.
  Status legend: [ ] pending  [~] in-progress  [x] done  [!] blocked
-->

# Tasks: Project subtitle in the projects-list export

| | |
|---|---|
| **Plan** | ./plan.md |
| **Spec** | ./spec.md |
| **Status** | not-started |

## Parallelization

- Tasks with the **same `Group`** value have no interdependencies and run in parallel.
- A task only starts once everything in its `Depends` list is `[x]`.

## Environment / command prefix (REQUIRED for all downstream agents)

Every Ruby / rspec / rubocop command **MUST** be prefixed with the rbenv + gitshim
PATH and Spring disabled:

```bash
export PATH="$HOME/.rbenv/versions/4.0.2/bin:/Users/renatomdelpaiva/Documents/dev/openproject-dev/tmp/gitshim:$PATH"; export DISABLE_SPRING=1
```

- **Non-`:js` specs** (select/KEYS unit, CSV integration, PDF integration) only
  need the prefix above. They do **not** need a frontend server.
- **`:js` feature specs** additionally require:
  - `OS_ACTIVITY_MODE=disable`
  - `FE_PORT=4250` — OpenProject's `ng serve` port for tests (4200 is taken on
    this machine), and `ng serve` must be running on **4250**.

  Example `:js` invocation:

  ```bash
  export PATH="$HOME/.rbenv/versions/4.0.2/bin:/Users/renatomdelpaiva/Documents/dev/openproject-dev/tmp/gitshim:$PATH"; export DISABLE_SPRING=1
  OS_ACTIVITY_MODE=disable FE_PORT=4250 bundle exec rspec spec/features/projects/lists/columns_spec.rb
  ```

## Task list

| ID | Status | Agent | Description | Files | Depends | Group | Done when |
|----|--------|-------|-------------|-------|---------|-------|-----------|
| T1 | [ ] | op-backend | Add `:subtitle` to `Queries::Projects::Selects::Default::KEYS`, placed right after `:name` (before `:public`/`:description`). This is the single load-bearing app change; it makes `subtitle` a valid select/column for query, UI picker, API v3, CSV and PDF. Do NOT touch default selected columns (`Setting.enabled_projects_columns`) — subtitle stays opt-in. No new i18n (reuse `activerecord.attributes.project.subtitle`). | `app/models/queries/projects/selects/default.rb` | — | A | `:subtitle` is in `KEYS`; `Queries::Projects::Selects::Default.key` matches `"subtitle"`; `all_available` includes it. |
| T2 | [ ] | op-backend | **Verify only** the projects PDF export path renders the new `subtitle` column generically and edit ONLY if a hardcoded attribute allow-list exists. Current read: `Report#select_fields` maps every non-`NotExistingSelect` select via `select.attribute`/`select.caption` with no allow-list, and `can_view_attribute?` only excludes `:name`/`:favorited` — so `subtitle` should render automatically with **no edit**. Confirm against `report.rb`, `info_map.rb`, `Project::PDFExport::Common::ProjectAttributes`. Record the finding in the Notes section below. | `app/models/projects/exports/pdf_export/report.rb`, `app/models/projects/exports/pdf_export/info_map.rb` (+ `Project::PDFExport::Common::ProjectAttributes`) — verify; edit only if allow-list found | T1 | A | Confirmed PDF renders selected `subtitle` generically; no edit needed (or minimal edit made + noted) and reason recorded in Notes. |
| T3 | [ ] | op-tester | Extend the **select/KEYS unit spec**: assert `:subtitle` is selectable — present in `KEYS`, matched by `.key` regex, returned by `all_available`; and that `select_for(:subtitle)` yields a `Selects::Default` (not `NotExistingSelect`) and appears in `available_selects` (API column validity), with caption = "Subtitle" via `Project.human_attribute_name(:subtitle)`. Non-`:js` — prefix only. | `spec/models/queries/projects/selects/default_spec.rb` | T1 | B | `bundle exec rspec spec/models/queries/projects/selects/default_spec.rb` green; covers selectability + caption + not-`NotExistingSelect`. |
| T4 | [ ] | op-tester | Extend the **CSV export integration spec** (add subtitle to `let(:query_columns)`). Cover: FR-1/FR-2/FR-3 — "Subtitle" header present + value emitted; FR-4 — blank subtitle → empty cell (not "null"/placeholder); FR-5 — subtitle with comma/quote/newline/non-ASCII parses intact via `CSV.parse`; FR-9 — 255-char value exported in full untruncated; FR-8 — existing columns unchanged when subtitle is selected. Non-`:js` — prefix only. | `spec/models/projects/exporter/csv_integration_spec.rb` | T1 | B | `bundle exec rspec spec/models/projects/exporter/csv_integration_spec.rb` green; all six FR cases asserted. |
| T5 | [ ] | op-tester | Extend the **PDF export integration spec**: assert subtitle renders as readable text in the PDF when selected, and blank subtitle produces no error / empty field. At minimum assert no error + value present. Non-`:js` — prefix only. | `spec/models/projects/exports/pdf_spec.rb` | T1, T2 | B | `bundle exec rspec spec/models/projects/exports/pdf_spec.rb` green; subtitle value present, blank case errors-free. |
| T6 | [ ] | op-tester | Add a **`:js` projects-list feature spec**: in the configure-view modal add the "Subtitle" column, assert it shows in the list with the value (Scenario 1 visibility), assert it is **not** selected by default (opt-in / FR-8 default columns unchanged), and exercise the export (CSV) trigger to confirm subtitle is included. **MUST** run with the env prefix **plus** `OS_ACTIVITY_MODE=disable FE_PORT=4250` and `ng serve` on 4250. | `spec/features/projects/lists/columns_spec.rb` (and/or `spec/features/projects/export_spec.rb`) | T1 | B | `OS_ACTIVITY_MODE=disable FE_PORT=4250 bundle exec rspec <file>` green; column add + display + opt-in + export covered. |
| T7 | [ ] | op-tester | Extend the **export feature spec** for FR-6: a user who can see only a subset of projects exports the list with subtitle included and gets subtitles for **exactly** their visible projects — no extra projects, no subtitles for hidden projects; archived follow the existing rule. `:js` if it drives the browser export (prefix + `OS_ACTIVITY_MODE=disable FE_PORT=4250`); otherwise prefix only. | `spec/features/projects/export_spec.rb` | T1 | B | spec green; exported subtitle set == user-visible projects under permissions. |
| T8 | [ ] | op-reviewer | Final **lint + diff review** vs spec & plan: confirm the only app change is `:subtitle` in `Default::KEYS` (no default-column change, no new i18n/migration/formatter), specs cover every acceptance criterion (Scenario 1–4, FR-4/5/6/8/9) and the opt-in/not-default behavior. Run rubocop on changed Ruby, erb_lint if any ERB touched, and verify the `#subtitle` double-render (under name + own column) is acceptable / flag for product if not. | — (review of T1–T7 diff) | T1, T2, T3, T4, T5, T6, T7 | C | `bundle exec rubocop` (changed files) clean; criteria-to-spec mapping verified; double-render flagged or accepted. |

> **Groups:** A (T1, T2) — T2 verifies after T1's edit. B (T3–T7) — all specs run in parallel once T1 (and T2 for T5) is `[x]`. C (T8) — review last.

## Test-to-criteria coverage map

| Acceptance criterion / FR | Covered by |
|---|---|
| Scenario 1 — Subtitle column + value in export (FR-1/2/3) | T4 (CSV), T6 (feature) |
| Scenario 2 / FR-4 — blank subtitle → empty cell | T4 |
| Scenario 3 / FR-5 — special chars escaped, file valid | T4 |
| Scenario 4 / FR-6 — export matches visible projects | T7 |
| FR-7 — formats in scope (CSV + PDF) | T4 (CSV), T5 (PDF) |
| FR-8 — existing exports unchanged / opt-in | T4 (columns unchanged), T6 (not default-selected) |
| FR-9 — 255-char value untruncated | T4 |
| Select/API column validity (subtitle is a valid select) | T3 |
| PDF generic-render verification | T2 |

## Notes / decisions during implementation

- T2 finding (PDF allow-list): _record here whether PDF rendered subtitle with no edit (expected) or required a change._
- <Append anything the agents discover that changes the plan.>
