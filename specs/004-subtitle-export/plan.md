# Plan: Project subtitle in the projects-list export

| | |
|---|---|
| **Spec** | ./spec.md |
| **Status** | draft |
| **Created** | 2026-06-15 |

## Approach summary

The projects-list export (CSV + PDF) is **column-driven**: the exporter walks
`query.selects` (`Projects::Exports::QueryExporter#selected_columns`), so any
registered, selectable column is exported automatically. The whole feature is
therefore achieved by making `subtitle` a **selectable projects-list column**.

`subtitle` is a plain string attribute (`projects.subtitle`, ≤255, already
filtered via `Filters::SubtitleFilter`) and behaves exactly like `name`. The
plain-string projects columns (`name`, `description`, `id`, …) are **not**
separate Select subclasses — they are entries in
`Queries::Projects::Selects::Default::KEYS`, matched by a regex `.key`. So the
single load-bearing change is **adding `:subtitle` to `Default::KEYS`**. That one
edit makes `subtitle`:

- a valid `select`/column for the query (UI, API v3) via
  `Queries::Selects::AvailableSelects#select_for`,
- visible in the column picker (`projects_columns_options` → `available_selects`),
- captioned "Subtitle" via `Selects::Base#caption` → `Project.human_attribute_name(:subtitle)`,
- rendered in its own list column, and
- emitted in the CSV and PDF export.

**Rejected alternative:** a dedicated `Queries::Projects::Selects::Subtitle`
subclass + register it in `app/models/queries/projects.rb`. Unnecessary — that
pattern is only used for non-trivial columns (status, custom fields, dates).
`subtitle` mirrors `name`, which lives in `Default::KEYS`, so we follow `name`.

**Default selected columns are NOT changed** (subtitle is opt-in): the change is
to `KEYS` (what is *selectable*), not to `Setting.enabled_projects_columns` (what
is *selected by default*).

## Affected layers

- [x] **Data model / migrations** — none (attribute already exists). *No migration.*
- [ ] **Business logic** — none.
- [ ] **Module engine** — none.
- [x] **REST API v3** — no code change; `subtitle` becomes a valid query select
  automatically via the shared `AvailableSelects` machinery. Covered by a schema/query spec.
- [x] **Hotwire UI** — list column rendering reuses the existing
  `Projects::RowComponent#subtitle` helper (no new component); column picker is
  data-driven (no change). One small reuse decision noted below.
- [ ] **Legacy Angular** — none.
- [x] **Permissions / i18n** — no new permission; **no new i18n** (reuse
  `activerecord.attributes.project.subtitle` = "Subtitle", already present at
  `config/locales/en.yml:1934`).

## Data model & migrations

None. `projects.subtitle` already exists, is validated (`length: { maximum: 255 }`),
and normalized (`app/models/project.rb`). No data migration.

## Services & contracts

None. Export is read-only; no Create/Update/Delete services or contracts touched.

## API (v3)

No new/changed endpoint or representer. The projects query exposes selectable
columns through `ProjectQuery#available_selects` (the shared
`Queries::Selects::AvailableSelects` concern). Once `:subtitle` is in
`Default::KEYS`:

- `select_for(:subtitle)` returns `Selects::Default.new(:subtitle)` (instead of
  `NotExistingSelect`), so `?select=...subtitle...` / `columns[]=subtitle` is valid.
- `available_selects` lists it (via `Default.all_available`).

Add a query/schema **spec** asserting `subtitle` is an available select and that
selecting it does not yield a `NotExistingSelect`.

## Frontend

- **List column rendering:** `Projects::RowComponent#column_value(column)` falls
  through to `send(column.attribute)` for plain columns. A `#subtitle` method
  **already exists** (`app/components/projects/row_component.rb:165`) — it returns
  a muted `Primer::Beta::Text` (or `nil`/blank when `project.subtitle` is blank).
  Adding `subtitle` to `KEYS` makes the dedicated column render via this same
  method, with no new component. (It currently also renders inside the `name`
  cell; that stays — subtitle still shows under the name, and additionally in its
  own column when selected. This matches the spec: default columns unchanged,
  subtitle opt-in.)
  - **Decision / watch-item:** confirm the existing `#subtitle` helper is
    acceptable as a standalone cell. If a plain-text cell (no muted styling) is
    preferred for the dedicated column, special-case it like `created_at`/`name`
    do; otherwise reuse as-is. Recommended: **reuse as-is** (least change).
- **Column picker:** `projects_columns_options` (`app/helpers/projects_helper.rb`)
  is built from `available_selects`, so "Subtitle" appears automatically, sorted
  by caption. No change.
- i18n: none (reuse `activerecord.attributes.project.subtitle`).

## Export behavior (CSV + PDF)

- **CSV — automatic, no per-format code.** `Projects::Exports::CSV` includes
  `Exports::Concerns::CSV`; `csv_headers` = `columns.pluck(:caption)` and
  `csv_row` = `format_attribute(record, column[:name], :csv)`. With no registered
  formatter for `subtitle`, `Exports::Formatters::Default` applies:
  `object.try(:subtitle)` → `value.to_s`, and `nil → ""` (FR-4 empty cell).
  Special-char escaping/quoting and the UTF-8 BOM are handled by Ruby `CSV.generate`
  + the existing `success` BOM prefix (FR-5). 255-char value passes through
  unmodified (FR-9). **No new formatter needed** (subtitle is plain text like `name`).
- **PDF — automatic, no per-format code.** `Projects::Exports::PDF` is also a
  `QueryExporter` driven by the same `columns`/`selected_columns`. The
  project-attributes/report rendering iterates selected columns and formats plain
  string attributes through the same `Default` formatter path; a "Subtitle" field
  renders as readable text in the corresponding cell (empty when blank). Confirm
  during implementation that the PDF report renderer
  (`app/models/projects/exports/pdf_export/report.rb` /
  `Project::PDFExport::Common::ProjectAttributes`) has no allow-list that would
  need `subtitle` added (watch-item; see Risks).
- **No XLS** (projects have no XLS exporter — out of scope, confirmed in spec).
- Visibility/permissions (FR-6) are unchanged: `QueryExporter#all_projects`
  already scopes to `:export_projects` (admins incl. archived). Adding a column
  does not widen the project set.
- FR-8 (existing exports unchanged): subtitle is opt-in (not in default
  `enabled_projects_columns`), so existing exports are byte-for-byte unchanged.

## Permissions

No new permission or policy. Export already requires `:export_projects`; column
visibility follows the same per-project rules as the list.

## Test strategy

| Spec | File (new/extend) | Covers |
|------|-------------------|--------|
| Select / KEYS unit | `spec/models/queries/projects/selects/default_spec.rb` (extend) | `:subtitle` ∈ `KEYS`, matched by `.key`, in `all_available`; caption = "Subtitle" |
| Query/API select valid | new `spec/models/project_query_spec.rb` case (or selects spec) | `select(:subtitle)` yields a `Default` select, not `NotExistingSelect`; appears in `available_selects` — maps to API column validity |
| CSV export (integration) | `spec/models/projects/exporter/csv_integration_spec.rb` (extend, `let(:query_columns)`) | FR-1/2/3 header "Subtitle" + value; FR-4 empty cell when blank; FR-5 special chars (comma/quote/newline/non-ASCII) parse intact via `CSV.parse`; FR-9 255-char full value |
| PDF export | `spec/models/projects/exports/pdf_spec.rb` (extend) | subtitle column renders as text in PDF; blank → empty (at minimum assert no error + value present). If PDF assertion is impractical, CSV spec is the floor per spec. |
| Projects-list column display (feature) | `spec/features/projects/lists/columns_spec.rb` (extend) | selecting "Subtitle" in the configure-view modal shows the column with the value (Scenario 1 visibility); default columns unchanged |
| Export feature (visibility) | `spec/features/projects/export_spec.rb` (extend) | FR-6: exported subtitles match the user's visible projects under permissions |

Feature specs need Capybara/Cuprite (configure-view modal + export trigger).
Acceptance-criteria mapping: Scenario1→CSV+feature; Scenario2/FR-4→CSV empty;
Scenario3/FR-5→CSV special-char; Scenario4/FR-6→export feature; FR-8→default-
columns-unchanged assertion; FR-9→255-char CSV case.

## Risks & rollout

- **PDF allow-list (primary uncertainty):** confirm the projects PDF report path
  (`pdf_export/report.rb`, `Project::PDFExport::Common::ProjectAttributes`)
  renders arbitrary selected string columns generically. If it has a hardcoded
  field map, adding `subtitle` there is the only extra hook. CSV is confirmed
  fully automatic; PDF is *expected* automatic but must be verified.
- **`#subtitle` double-render:** subtitle shows both under `name` and in the new
  column. Intended and spec-compatible; flag for reviewer in case product wants
  it suppressed in one place (out of current scope).
- **No migration / no enterprise/BIM / no feature flag.** Backwards compatible:
  opt-in column, existing exports unchanged (FR-8).
- **i18n:** none added; `i18n-tasks` should stay green.

## File-level change map

| Path | Action | Notes |
|------|--------|-------|
| `app/models/queries/projects/selects/default.rb` | **edit** | Add `:subtitle` to `KEYS` (e.g. after `name`). **The one load-bearing change.** |
| `app/components/projects/row_component.rb` | verify / maybe edit | `#subtitle` (line ~165) already renders the cell via `column_value`→`send(:subtitle)`. Reuse as-is; only edit if a plain-text dedicated cell is preferred. |
| `app/models/projects/exports/pdf_export/report.rb` (+ `Project::PDFExport::Common::ProjectAttributes`) | verify / maybe edit | Confirm generic column rendering; add `subtitle` only if a hardcoded field map exists. |
| `spec/models/queries/projects/selects/default_spec.rb` | edit | Assert `:subtitle` selectable + caption. |
| `spec/models/projects/exporter/csv_integration_spec.rb` | edit | Subtitle CSV: header, value, empty, special chars, 255 chars. |
| `spec/models/projects/exports/pdf_spec.rb` | edit | Subtitle renders in PDF (or document CSV-only floor). |
| `spec/features/projects/lists/columns_spec.rb` | edit | Select "Subtitle" column → visible in list. |
| `spec/features/projects/export_spec.rb` | edit | FR-6 visibility of subtitles in export. |
| (optional) `spec/models/project_query_spec.rb` | add/edit | `subtitle` is a valid select (API column validity). |

**No new application files. No migration. No new i18n. No new formatter.**
