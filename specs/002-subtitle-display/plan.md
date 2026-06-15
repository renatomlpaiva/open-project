<!--
  PLAN — the HOW. Maps the approved spec onto OpenProject's real architecture.
  Filled in by the `op-planner` agent via /plan. Reference concrete files/dirs so
  /tasks can split the work cleanly across agents. See AGENTS.md "Architecture".
-->

# Plan: Display project subtitle

| | |
|---|---|
| **Spec** | ./spec.md |
| **Status** | draft |
| **Created** | 2026-06-15 |

## Approach summary

Feature 002 is purely a **read-only display** of the existing `Project#subtitle` column
(added in feature 001) in two server-rendered Hotwire/Primer ViewComponent surfaces:
the projects list/index row and the project Overview page header. No backend, model,
service, contract, API, permission, or query changes are needed — both surfaces already
load full `Project` records and already gate on the project's own visibility, so the
subtitle "rides" the existing name visibility for free.

In the **projects list** we add a secondary `Primer::Beta::Text` line inside the existing
`projects-table--name` cell of `Projects::RowComponent`, mirroring the existing
`projects-table--name-description` pattern already used there for the workspace-type badge.
We adjust the cell's flex layout to stack name + subtitle vertically. In the **Overview
heading** we use the `Primer::OpenProject::PageHeader#with_description` slot (already used
across the app for header descriptions) in `Overviews::PageHeaderComponent` to render the
subtitle beneath the title. Both render the value escaped, single-line, truncated with the
native `title` tooltip. Rejected alternative: adding a toggleable query column to the
projects list — explicitly out of scope per the spec Decisions (inline secondary text only).

## Affected layers

- [ ] **Data model / migrations** — none (column exists from 001)
- [ ] **Business logic** — none
- [ ] **Module engine** — only the Overview header ViewComponent (display)
- [ ] **REST API v3** — none (subtitle already exposed by 001)
- [x] **Hotwire UI** — `app/components/projects/row_component.*`, the projects list sass, and `modules/overviews/app/components/overviews/page_header_component.*` (ViewComponents, no Stimulus/Turbo needed)
- [ ] **Legacy Angular** — none
- [x] **Permissions / i18n** — no new permission; one optional i18n aria/label key (see below). No new permission check.

## Data model & migrations

None. `Project#subtitle` already exists:
- `app/models/project.rb:165` — `validates :subtitle, length: { maximum: 255 }`
- `app/models/project.rb:168` — `normalizes :subtitle, with: ->(s){ s&.gsub(/[\r\n]+/," ")&.squish.presence }`

Because of the `normalizes` rule, a stored subtitle is already single-line and
whitespace-only input is persisted as `nil`. Therefore the display guard is simply
`project.subtitle.present?` — this satisfies FR-3 (no element when empty) and the
"whitespace-only ⇒ nothing" edge case with no extra handling.

## Services & contracts

None. Display-only.

## API (v3)

None. (Subtitle exposure was delivered in feature 001.)

## Frontend

All changes are server-rendered Primer ViewComponents; no Stimulus/Turbo controllers.

### 1. Projects list row — `Projects::RowComponent`

The name cell is built in `RowComponent#name` (`app/components/projects/row_component.rb:153`),
which `safe_join`s `[hierarchy_icon, name_link_section, archived_label, workspace_type_badge]`
into `div.projects-table--name`. The project link is `name_link_section`
(`span.projects-table--name-text`).

- Add a private `subtitle` method that returns `nil` unless `project.subtitle.present?`,
  otherwise renders a `Primer::Beta::Text` muted/secondary line, mirroring the existing
  `workspace_type_badge` which already does
  `Primer::Beta::Text.new(classes: "projects-table--name-description")`
  (`row_component.rb:178`). Render with `font_size: :small`, `color: :muted`, the value as
  the text content, and `title: project.subtitle` so the native tooltip exposes the full
  value when truncated. ViewComponent/Primer HTML-escapes the block content, satisfying FR-6.
- Insert `subtitle` into the `name` content array. Because the subtitle must appear **beneath**
  the name (not beside it, where the workspace badge sits), wrap `name_link_section` (+ archived
  label/workspace badge) on the first line and the subtitle on a second line — see the sass
  change below — so place the subtitle as the last element of the array and let CSS stack it.

### 2. Projects list styles — `_projects_list.sass`

`frontend/src/global_styles/content/_projects_list.sass:77-87` currently lays the name cell
out as a single-row flex (`td.name > .projects-table--name { display: flex; gap: 8px }`) with
`.projects-table--name-text` using `@include text-shortener; white-space: nowrap`.

- Restructure so the name + badges stay on one row but the subtitle drops to a second line.
  Simplest robust approach: keep the existing row flex for the name/badges group and add a
  rule for the new subtitle line styled like `.projects-table--name-description` (which
  `@extend %autocomplete-description` — the established muted secondary look) plus
  `@include text-shortener; white-space: nowrap` so a long subtitle truncates with an ellipsis
  on a single line. Confirm the chosen markup wraps name+badges so the subtitle sits below;
  if the existing flat flex makes vertical stacking awkward, change the name container to
  `flex-direction: column` for the outer wrapper or introduce one inner wrapper span — keep
  the diff minimal and reuse `%autocomplete-description` / `text-shortener` rather than new ad-hoc styles.

### 3. Overview heading — `Overviews::PageHeaderComponent`

`modules/overviews/app/components/overviews/page_header_component.html.erb:3-4` renders
`Primer::OpenProject::PageHeader` with `header.with_title(variant: :medium) { page_title }`.
`page_title` (`page_header_component.rb:60`) returns `project.name`.

- Add `header.with_description { project.subtitle } if project.subtitle.present?` immediately
  after `with_title`. The `with_description` slot is the established place for secondary header
  text (see `app/components/settings/project_custom_fields/header_component.html.erb:5` and the
  project-phase-definitions headers). It renders escaped content beneath the title, visually
  subordinate (FR-10), and is omitted entirely when absent (FR-3).
- Add `title: project.subtitle` (and the truncation single-line styling) on the description so a
  long value truncates with a tooltip per the Decisions. If the `with_description` slot does not
  expose a `title`/single-line affordance directly, pass a `Primer::Beta::Text` block with
  `title:` + a truncation class, or render the description content via a small wrapper — confirm
  the slot's accepted arguments against the installed `openproject-primer_view_components` gem at
  implementation time (the gem was not installed in the planning sandbox, so the exact slot
  signature must be verified by the implementing agent).
- Archived: the Overview header already renders for archived projects (the archive action exists
  in this same component), so the subtitle shows for archived too with no extra work (Decision: shown).

### i18n

The subtitle **value** is user content shown verbatim — no translation. No new visible label is
required (it is plain adjacent secondary text per the Accessibility decision; no
`aria-describedby`). If a screen-reader/aria label is deemed desirable for the secondary line,
add a single translatable key (e.g. `projects.subtitle` / an aria label) under `config/locales/en.yml`
and reference it via `I18n.t`; otherwise no locale change. Recommend: **no new key** unless review
asks for one (FR-8 only bites if a label is introduced).

## Permissions

None new. Both surfaces already gate on whether the user can see the project (the list query
already filters visible projects; the Overview page is reached through normal project
authorization). The subtitle inherits exactly that audience (FR-5, scenario 7) with no added
policy check.

## Test strategy

All RSpec; no Vitest needed (no TS/Stimulus). Feature specs run under the default
Capybara/Cuprite stack already used by the projects/overviews feature suites.

| Spec | Type | Covers (acceptance criteria) |
|------|------|------------------------------|
| `spec/components/projects/row_component_spec.rb` (extend) | component | Renders subtitle as secondary text when present; renders nothing (no extra element/label) when blank/nil; value is HTML-escaped; includes `title` attr for tooltip → FR-1, FR-3, FR-6, FR-7, FR-10 |
| `modules/overviews/spec/components/overviews/page_header_component_spec.rb` (extend) | component | `with_description`/subtitle present vs absent; escaped; shown for archived project → FR-2, FR-3, FR-6, archived decision |
| `spec/features/projects/lists/` (new or extend, e.g. a `subtitle_spec.rb`) | feature (Cuprite) | List shows subtitle beneath name for a project with one; no placeholder when absent; updating/clearing subtitle in settings reflected on next render; not shown for a project the user cannot see → FR-1, FR-3, FR-5, FR-9, scenarios 1,3,7 |
| `modules/overviews/spec/features/` (new, e.g. `project_subtitle_spec.rb`) | feature (Cuprite) | Overview heading shows subtitle when present, nothing when absent; reflects updated/cleared value; shown for archived → FR-2, FR-3, FR-9, scenarios 2,4 |

Read-only + escaping (FR-4, FR-6) are asserted at the component level (no edit control rendered,
markup-like input rendered as literal text). FR-9 (current value after edit/clear) is asserted in
the feature specs by changing the value via the project settings subtitle form and re-rendering.

## Risks & rollout

- **Primer slot signature for the Overview description tooltip/truncation**: the
  `with_description` slot's exact support for a `title` attribute and single-line truncation
  must be confirmed against the installed `openproject-primer_view_components` gem (it was not
  installed in the planning sandbox). Low risk — fallback is to render a `Primer::Beta::Text`
  block with the `title:` and a truncation class inside the slot.
- **List name-cell layout**: the current cell is a single-row flex shared with the
  workspace-type badge and archived label. Stacking the subtitle on a second line must not
  disturb hierarchy indentation or the badge row. Mitigate by reusing the existing
  `%autocomplete-description` + `text-shortener` mixins and keeping markup changes minimal;
  verify visually for child/indented rows.
- **No migration / no data risk**; no enterprise/BIM-specific behavior; no feature flag needed.
- **Backwards compat**: projects created before 001 have `subtitle = nil` → guard renders nothing.
- **Performance**: negligible — `subtitle` is already loaded on the `Project` records both
  surfaces fetch; no extra queries.

## File-level change map

| Path | Action | Notes |
|------|--------|-------|
| `app/components/projects/row_component.rb` | edit | Add private `subtitle` method (guarded by `project.subtitle.present?`) rendering a muted `Primer::Beta::Text` with `title:` tooltip; add it to the `#name` content array as the second line. |
| `frontend/src/global_styles/content/_projects_list.sass` | edit | Stack name/badges row + subtitle line in `td.name > .projects-table--name`; style subtitle line via `%autocomplete-description` + `text-shortener` (single-line ellipsis). |
| `modules/overviews/app/components/overviews/page_header_component.html.erb` | edit | Add `header.with_description { project.subtitle } if project.subtitle.present?` after `with_title`, with single-line truncation + `title` tooltip. |
| `spec/components/projects/row_component_spec.rb` | edit | Add examples: present/absent subtitle, escaping, `title` attr. |
| `modules/overviews/spec/components/overviews/page_header_component_spec.rb` | edit | Add examples: present/absent subtitle, escaping, archived. |
| `spec/features/projects/lists/subtitle_spec.rb` | add | List feature: shown beneath name, absent ⇒ nothing, reflects edit/clear, hidden when project not visible. |
| `modules/overviews/spec/features/project_subtitle_spec.rb` | add | Overview header feature: shown/absent, reflects edit/clear, archived. |
| `config/locales/en.yml` | (optional) | Only if an aria/label key is introduced for the secondary line; default recommendation is no change. |
