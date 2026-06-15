<!--
  PLAN — the HOW. Maps the approved spec onto OpenProject's real architecture.
-->

# Plan: Filter projects list by subtitle

| | |
|---|---|
| **Spec** | ./spec.md |
| **Status** | draft |
| **Created** | 2026-06-15 |

## Approach summary

Add a `Queries::Projects::Filters::SubtitleFilter` as a near-exact copy of the existing
`Queries::Projects::Filters::NameFilter`, swapping the column from `projects.name` to
`projects.subtitle` and the filter key from `:name` to `:subtitle`. Register it on the
`ProjectQuery` and add it to the projects-list filter UI allowlist. The API v3 exposure
and visibility/permission handling come for free from the existing project-query
infrastructure (the `filters=` collection param is driven entirely by the registered
filter and its `self.key`; visibility is enforced by the query's base scope, not the
filter). Rejected alternative: a generic "string-column" filter abstraction shared by
name + subtitle — out of scope and riskier than a literal mirror; the spec explicitly
asks to mirror the name filter exactly.

## Affected layers

- [ ] **Data model / migrations** — already delivered (feature 001 migration `20260614120000_add_subtitle_to_projects.rb`; column `projects.subtitle character varying`). No change.
- [x] **Business logic** — new query filter class under `app/models/queries/projects/filters/` + registration in `app/models/queries/projects.rb`.
- [ ] **Module engine** — n/a.
- [x] **REST API v3** — no new code; exposure is automatic via the registered filter (see API section). Verified by request spec.
- [x] **Hotwire UI** — add the filter to the explicit allowlist in `Projects::ProjectsFiltersComponent`.
- [ ] **Legacy Angular** — n/a (projects list filter UI is the Hotwire/ViewComponent `Filter::FilterComponent`, server-driven).
- [x] **Permissions / i18n** — no new permission; **no new i18n key** (label resolves from existing `activerecord.attributes.project.subtitle`).

## Data model & migrations

None. `projects.subtitle` (optional `string`, ≤255) already exists from feature 001.
No data migration. No index added — the name filter has no dedicated index either, and
the spec mandates exact parity (a subtitle index is out of scope).

## Services & contracts

None. Project query filters are pure query objects; there is no Create/Update/Delete
service or contract involved. Authorization is **not** in the filter: the project query's
base scope already restricts to visible projects (FR-7 satisfied without filter-level code),
exactly as it does for the name filter.

## Business logic — the filter class

New file `app/models/queries/projects/filters/subtitle_filter.rb`, a literal copy of
`name_filter.rb` with these substitutions:

- Class: `Queries::Projects::Filters::SubtitleFilter < Queries::Projects::Filters::Base`
- `self.key` → `:subtitle`
- All `projects.name` → `projects.subtitle` (in `#where` for `=`, `!`, `~`, `**`, `!~`, and the `**` term loop)
- `#type` → `:string` (unchanged)
- **Drop** the `human_name` override. NameFilter overrides it with `I18n.t(:label_name)`;
  for subtitle we rely on `Base#human_name` → `Project.human_attribute_name(:subtitle)`,
  which already resolves to "Subtitle". This means **no new locale key** (FR-4 satisfied
  via the existing `activerecord.attributes.project.subtitle`).
- Keep the private `#sql_value` helper verbatim (operator-dependent `LOWER(...)`/`%...%`
  handling — gives literal `%`/`_`, case-insensitivity, and `**` multi-word behavior for free).

Operators come from `Queries::Projects::Filters::Base`/`Queries::Filters::Base` defaults
identically to the name filter — no operator declaration needed (the name filter declares
none either; the implemented `#where` branches define the effective set `= ! ~ ** !~`).

## Registration

In `app/models/queries/projects.rb`, add `filter Filters::SubtitleFilter` to the
`Queries::Register.register(ProjectQuery)` block (place alphabetically near
`NameFilter` / `ParentFilter`). This single line makes the filter usable by both the UI
component (which reads registered filters) and the API v3 `filters=` param.

## API (v3)

No new Grape code and no representer change. Project filtering in API v3 is driven by the
`filters=` query param on the `:projects` collection path; the param parser instantiates
whatever filter matches the JSON key against the registered project-query filters. Because
`SubtitleFilter.key == :subtitle`, a request like
`?filters=[{"subtitle":{"operator":"~","values":["alpha"]}}]` works once the filter is
registered. Visibility is enforced by the query base scope (FR-6/FR-7/parity).

Note: project-query filters do **not** flow through the work-package
`FilterDependencyRepresenterFactory` (that factory has no `String`→representer mapping;
the name filter is not exposed there either), so no entry is needed in
`@specific_conversion` and no `*DependencyRepresenter` is required. The stable, documented
filter key (FR-5) is simply `subtitle`.

## Frontend

Server-driven via `Projects::ProjectsFiltersComponent < Filter::FilterComponent`
(`app/components/projects/projects_filters_component.rb`). Its `#allowed_filter?` uses an
**explicit allowlist** — registering the filter is **not** sufficient for the UI. Add
`Queries::Projects::Filters::SubtitleFilter` to that `allowlist` array (alphabetically near
`NameAndIdentifierFilter`). The dropdown label and the operator/value controls are rendered
generically from the filter's `human_name`/`type`, so no new Stimulus controller, Turbo
frame, or ViewComponent is needed. No Angular changes.

## Permissions

None. No new permission, role, or policy. Existing project-visibility rules apply unchanged.

## i18n

No new key. The filter label resolves from the pre-existing
`activerecord.attributes.project.subtitle` ("Subtitle", en.yml line 1934) via
`Project.human_attribute_name(:subtitle)`. Run `bundle exec i18n-tasks unused` / `missing`
to confirm nothing is introduced or orphaned.

## Test strategy

| Test | File (new) | Covers |
|------|-----------|--------|
| **Filter unit spec** | `spec/models/queries/projects/filters/subtitle_filter_spec.rb` | Mirror `name_filter_spec.rb`: `it_behaves_like "basic query filter"` with `class_key :subtitle`, `human_name "Subtitle"`, `type :string`, `allowed_values` nil; `#apply_to` SQL assertions for `= ! ~ !~` (and ideally `**`) against `LOWER(projects.subtitle)`. Covers FR-1, FR-2, FR-3, FR-9, FR-10 (no-subtitle excluded from LIKE), special-char literalness. |
| **API request spec** | add a context to `spec/requests/api/v3/projects/index_resource_spec.rb` | `filters = [{ subtitle: { operator: "~", values: ["alpha"] } }]`; assert collection contains only matching+visible projects, empty result when none match, and a non-visible matching project is excluded. Covers FR-5, FR-6, FR-7, FR-8; scenarios 2, 4, 6, 7. |
| **Feature (UI) spec** | add to `spec/features/projects/lists/filters_spec.rb` (Capybara/Cuprite) | Open the filter list, confirm "Subtitle" is offered (scenario 3 / FR-4); apply a "contains" value, assert only matching visible projects are listed and mixed-case matches (scenarios 1, 5). |

Acceptance-criteria map: AC1→unit+feature; AC2 (UI offered)→feature; AC3 (API key)→request;
AC4 (UI/API parity)→request + feature; AC5 (visibility)→request; AC6 (empty)→request;
AC7 (no subtitle excluded)→unit; AC8 (operator set parity)→unit.

## Risks & rollout

- **Frontend allowlist is the easy-to-miss step.** Registering the filter without adding it
  to `ProjectsFiltersComponent#allowed_filter?` would pass API tests but silently omit the
  filter from the UI (breaking FR-4 / scenario 3). The feature spec guards this.
- **`human_name` decision.** Relying on `Base#human_name` (vs. NameFilter's `label_name`
  override) is deliberate to avoid a new locale key; if `activerecord.attributes.project.subtitle`
  were ever removed/renamed the label would fall back to a humanized "Subtitle". Low risk —
  key is owned by feature 001 and asserted in the unit spec.
- **No DB index** on `subtitle` (parity with name). `LIKE '%term%'` is non-sargable; same
  performance profile as the existing name filter — acceptable and in scope only as parity.
- **Editions:** no Enterprise/BIM-specific code; community filter infra only. No feature flag
  needed. Fully backwards compatible (additive registered filter; old stored queries unaffected).

## File-level change map

| Path | Action | Notes |
|------|--------|-------|
| `app/models/queries/projects/filters/subtitle_filter.rb` | **add** | Copy of `name_filter.rb`; `projects.name`→`projects.subtitle`, `self.key :subtitle`, drop `human_name` override, keep `#sql_value`. |
| `app/models/queries/projects.rb` | **edit** | Add `filter Filters::SubtitleFilter` to the `ProjectQuery` register block (near `NameFilter`). |
| `app/components/projects/projects_filters_component.rb` | **edit** | Add `Queries::Projects::Filters::SubtitleFilter` to the `allowlist` in `#allowed_filter?`. |
| `spec/models/queries/projects/filters/subtitle_filter_spec.rb` | **add** | Mirror `name_filter_spec.rb`. |
| `spec/requests/api/v3/projects/index_resource_spec.rb` | **edit** | Add a "filtering by subtitle" context (match / empty / visibility). |
| `spec/features/projects/lists/filters_spec.rb` | **edit** | Add subtitle-filter UI scenario (offered + contains + case-insensitive). |
| `config/locales/en.yml` | **no change** | Reuses existing `activerecord.attributes.project.subtitle`. |
| `lib/api/v3/**` | **no change** | Exposure automatic via registered filter + `filters=` param. |
| `db/migrate/**` | **no change** | Column already exists (feature 001). |
