<!--
  TASKS — the executable breakdown. Filled in by `op-planner` via /tasks and
  consumed by /implement. Each task is small, names ONE agent, lists its files,
  its dependencies, and a parallel group. Tasks in the same group run concurrently.
  Status legend: [ ] pending  [~] in-progress  [x] done  [!] blocked
-->

# Tasks: Display project subtitle

| | |
|---|---|
| **Plan** | ./plan.md |
| **Spec** | ./spec.md |
| **Status** | not-started |

## Environment (REQUIRED for every Ruby/rspec/rubocop/erb_lint command)

System Ruby is 2.6 and fails; you MUST prefix any Ruby-toolchain command with:

```bash
export PATH="$HOME/.rbenv/versions/4.0.2/bin:/Users/renatomdelpaiva/Documents/dev/openproject-dev/tmp/gitshim:$PATH"
export DISABLE_SPRING=1
```

(This is why `bundle show` looked empty during planning.) Frontend-only commands
(`cd frontend && npx eslint ...`) do not need this, but tasks that touch sass/ERB and run
`erb_lint` still do.

## Parallelization

- Tasks with the **same `Group`** value have no interdependencies and run in parallel.
- A task only starts once everything in its `Depends` list is `[x]`.
- This is a **display-only** feature: no backend / model / service / contract / API / permission / i18n-key work.
- The two display surfaces (projects list row, Overview heading) are independent → **Group A**, run in parallel.
- Tester tasks depend on the display tasks they cover → **Group B**, run in parallel after A.
- Final reviewer task → **Group C**.

## Task list

| ID | Status | Agent | Description | Files | Depends | Group | Done when |
|----|--------|-------|-------------|-------|---------|-------|-----------|
| T1 | [ ] | op-frontend | **Projects list row — subtitle line.** Add a private `subtitle` method to `RowComponent` returning `nil` unless `project.subtitle.present?`, else a muted `Primer::Beta::Text` (`font_size: :small`, `color: :muted`, `title: project.subtitle`) mirroring the existing `workspace_type_badge`. Append it as the **last/second-line** element of the `#name` content array. Update `_projects_list.sass` so name+badges stay on row 1 and the subtitle drops to a single-line, ellipsis-truncated second line, reusing `%autocomplete-description` + `text-shortener` (keep diff minimal). | `app/components/projects/row_component.rb`, `frontend/src/global_styles/content/_projects_list.sass` | — | A | Subtitle renders beneath the name only when present; nothing rendered when blank/nil; long value truncates single-line with `title` tooltip; markup-like content is escaped; child/indented + archived rows still lay out correctly; `erb_lint`, `rubocop`, and `cd frontend && npx eslint src/` (stylelint if configured) clean. |
| T2 | [ ] | op-frontend | **Overview heading — subtitle description.** In `page_header_component.html.erb`, after `header.with_title(...)`, add `header.with_description { project.subtitle } if project.subtitle.present?`, rendered escaped, single-line, truncated, with `title: project.subtitle`. Verify the installed `openproject-primer_view_components` `with_description` slot's accepted args at implementation time; if it doesn't expose `title`/single-line truncation directly, render a `Primer::Beta::Text` block with `title:` + a truncation class inside the slot (per plan Risks). Subtitle shows for archived projects (no extra work). | `modules/overviews/app/components/overviews/page_header_component.html.erb` (and `.rb` only if a helper is needed) | — | A | Subtitle renders beneath the title only when present; omitted entirely when absent/blank; escaped; single-line truncation + `title` tooltip; shown for archived; visually subordinate to the title; `erb_lint` + `rubocop` clean. |
| T3 | [ ] | op-tester | **Projects list specs.** Extend `row_component_spec.rb` (component): subtitle shown as secondary text when present; **no** element/label/placeholder when nil/blank; HTML-like value escaped (literal text, not interpreted); `title` attribute present for tooltip. Add `spec/features/projects/lists/subtitle_spec.rb` (Cuprite feature): subtitle shown beneath name in the list; absent ⇒ nothing; updating then clearing the subtitle via project settings is reflected on the next list render; not shown for a project the user cannot see. | `spec/components/projects/row_component_spec.rb`, `spec/features/projects/lists/subtitle_spec.rb` | T1 | B | `bin/rspec` green for both files (with the env prefix); covers FR-1, FR-3, FR-5, FR-6, FR-7, FR-9, FR-10 and scenarios 1, 3, 7. |
| T4 | [ ] | op-tester | **Overview heading specs.** Extend `page_header_component_spec.rb` (component): description/subtitle present vs absent; escaped; shown for an archived project. Add `modules/overviews/spec/features/project_subtitle_spec.rb` (Cuprite feature): Overview heading shows subtitle when present, nothing when absent; reflects updated then cleared value; shown for archived. | `modules/overviews/spec/components/overviews/page_header_component_spec.rb`, `modules/overviews/spec/features/project_subtitle_spec.rb` | T2 | B | `bin/rspec` green for both files (with the env prefix); covers FR-2, FR-3, FR-6, FR-9, the archived decision, and scenarios 2, 4. |
| T5 | [ ] | op-reviewer | **Final lint + diff review vs spec.** Review the full diff against `spec.md` acceptance criteria + plan decisions: confirm guard is `present?`-only (no placeholder when absent), escaping, single-line truncation + `title`, archived behavior, visibility-rides-name (no new permission), no new i18n key unless one was deliberately added (then it's translatable). Run all linters across the changed files. | — (review only) | T3, T4 | C | `rubocop`, `cd frontend && npx eslint src/`, and `erb_lint` clean on all changed files (env prefix applied); every acceptance-criteria checkbox in `spec.md` traces to a passing T3/T4 spec; no scope creep (no query column, no backend/API change). |

> Group A (T1, T2) runs in parallel. Group B (T3, T4) runs in parallel after A. Group C (T5) is last.

## Acceptance-criteria → task coverage

Each acceptance checkbox in `spec.md` is covered by at least one tester task; T1/T2 implement.

| Acceptance criterion (spec.md) | FRs | Implemented by | Verified by |
|--------------------------------|-----|----------------|-------------|
| Subtitle shown read-only beneath name in projects list (scenario 1) | FR-1, FR-4 | T1 | T3 |
| Subtitle shown read-only in Overview heading (scenario 2) | FR-2, FR-4 | T2 | T4 |
| No subtitle element/label/placeholder when absent, both surfaces (scenarios 3, 4) | FR-3 | T1, T2 | T3, T4 |
| Subtitle escaped / plain text, markup not executed (scenario 6) | FR-6 | T1, T2 | T3, T4 |
| Shown only to users who can see the project; never reveals hidden project (scenario 7) | FR-5 | T1 (rides existing visibility — no code) | T3 |
| Single-line secondary tagline, subordinate to name | FR-7, FR-10 | T1, T2 | T3, T4 |
| Updating/clearing in settings reflected on next render of both surfaces | FR-9 | T1, T2 | T3, T4 |
| Any introduced label/accessibility text uses translation keys (no hard-coded UI) | FR-8 | T1, T2 (recommendation: introduce none) | T5 (review gate) |

Read-only / no-edit-affordance (FR-4) and escaping (FR-6) are asserted at the component level
(no edit control rendered; markup-like input rendered as literal text). FR-9 is asserted in the
feature specs by changing the value via the project-settings subtitle form and re-rendering.

## Notes / decisions during implementation

- T2: confirm the `with_description` slot signature against the installed
  `openproject-primer_view_components` gem before relying on `title:`/single-line truncation;
  fallback is a `Primer::Beta::Text` block with `title:` + a truncation class inside the slot.
- T1: if the existing flat single-row flex makes vertical stacking awkward, switch the name
  container to `flex-direction: column` or add one inner wrapper span — keep the diff minimal and
  reuse `%autocomplete-description` + `text-shortener` rather than ad-hoc styles. Verify indented/child rows.
- Default recommendation per plan: **no new i18n key** and **no `config/locales/en.yml` change**
  unless review (T5) asks for an aria/label string — in which case it must be translatable (FR-8).
- <Append anything the agents discover that changes the plan.>
