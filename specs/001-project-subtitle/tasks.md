<!--
  TASKS — the executable breakdown. Filled in by `op-planner` via /tasks and
  consumed by /implement. Each task is small, names ONE agent, lists its files,
  its dependencies, and a parallel group. Tasks in the same group run concurrently.
  Status legend: [ ] pending  [~] in-progress  [x] done  [!] blocked
-->

# Tasks: Project subtitle

| | |
|---|---|
| **Plan** | ./plan.md |
| **Spec** | ./spec.md |
| **Status** | not-started |

## Parallelization

- Tasks with the **same `Group`** value have no interdependencies and run in parallel.
- A task only starts once everything in its `Depends` list is `[x]`.
- **op-frontend rule**: any frontend task MUST name the design-system / UI elements it
  touches. Here that is the OpenProject **project general-settings** form rendered by a
  **Primer ViewComponent** (`Primer::Forms::FormList` of `ApplicationForm` form objects:
  `NameForm`, `DescriptionForm`, `Submit`) — the subtitle is a single-line
  `Primer::Forms` `f.text_field` (NOT a rich-text editor).

## Task list

| ID | Status | Agent | Description | Files | Depends | Group | Done when |
|----|--------|-------|-------------|-------|---------|-------|-----------|
| T1 | [ ] | op-backend | Migration: add `subtitle` (`string`, null:true) to **both** `projects` and `project_journals`, mirroring `20250731144436_add_workspace_type_to_project.rb` (`change_table … bulk: false`). Let `db:migrate` regenerate `db/structure.sql` (commit, do not hand-edit). | `db/migrate/<ts>_add_subtitle_to_projects.rb` (add), `db/structure.sql` (regen) | — | A | `bundle exec rails db:migrate` runs clean; `subtitle` column present on both `projects` and `project_journals`; `structure.sql` regenerated |
| T2 | [ ] | op-backend | Model: `validates :subtitle, length: { maximum: 255 }`; `normalizes :subtitle, with: ->(v) { v&.gsub(/[\r\n]+/, " ")&.squish.presence }` (strip newlines + trim + collapse, whitespace-only → `nil`); add `"subtitle"` to `register_journal_formatted_fields … formatter_key: :plaintext`. No `presence`, no `acts_as_searchable` change. | `app/models/project.rb` (edit) | T1 | B | model loads; 255 valid / 256 invalid; whitespace-only normalizes to `nil`; embedded `\n`/`\r` collapse to single line |
| T3 | [ ] | op-backend | Contract: allow-list the attribute with `attribute :subtitle` on `BaseContract` (writable for create + update). No custom validate block, no policy change — `validate_user_allowed_to_manage` + `UpdateContract#manage_permission` (`:edit_project`) already gate writes. | `app/contracts/projects/base_contract.rb` (edit) | T2 | B | `subtitle` appears in writable attributes when user has `edit_project`; absent / rejected otherwise |
| T4 | [ ] | op-api | API v3 read: add plain `property :subtitle, render_nil: true` near `name` in the project representer (NOT `formattable_property` — plain text per FR-3/FR-7). Inherited payload representer makes it PATCH-writable automatically (verify, likely no edit). Schema: confirm contract-driven; only add `schema :subtitle, type: "String", required: false` if the schema is not auto-derived. | `lib/api/v3/projects/project_representer.rb` (edit); `lib/api/v3/projects/project_payload_representer.rb` (verify); `lib/api/v3/projects/schemas/project_schema_representer.rb` (verify/edit) | T3 | C | `GET /api/v3/projects/:id` body includes `subtitle` as plain string; `PATCH` with authorized user writes & reads it back |
| T5 | [ ] | op-frontend | Frontend form object: add `Projects::Settings::SubtitleForm` modeled on `name_form.rb` — an `ApplicationForm` (Primer ViewComponent) with a **single-line** `f.text_field name: :subtitle, label: attribute_name(:subtitle)` (NOT rich-text). Optional caption via i18n. | `app/forms/projects/settings/subtitle_form.rb` (add) | T3 | C | form object renders a single-line Primer `text_field`; label resolves from i18n; `erb_lint`/`rubocop` clean |
| T6 | [ ] | op-frontend | Wire the subtitle form into the **project general-settings** "Details" section: insert `Projects::Settings::SubtitleForm.new(f)` into the `Primer::Forms::FormList`, after `NameForm` / before `DescriptionForm`, so it persists via the existing `project_settings_general_path` Submit (`edit_project`-gated). | `app/components/projects/settings/general/show_component.html.erb` (edit) | T5 | C | settings page renders the subtitle field between name and description; saving via the existing Submit persists through `UpdateService`; `erb_lint` clean |
| T7 | [ ] | op-frontend | i18n: add `activerecord.attributes.project.subtitle: "Subtitle"` (and optional caption key) to `en.yml`; run `bundle exec i18n-tasks normalize` / `missing`. Reuse Rails' built-in `errors.messages.too_long` for the length message (no new key). No hard-coded UI strings (FR-10). | `config/locales/en.yml` (edit) | T3 | C | label key present; `i18n-tasks missing` clean; no hard-coded strings in T5/T6 |
| T8 | [ ] | op-tester | Model + journal specs: length 255 accepted / 256 rejected; multibyte counted as **characters** (255 multibyte accepted); normalization (trim, strip `\n`/`\r` to single line, whitespace-only → `nil`); optional/blank valid; **subtitle change creates a journal entry** old→new (`:plaintext`). Covers AC1(model), AC2(model), AC3, journaling Decision; FR-1/2/3/4/11. | `spec/models/project_spec.rb`, `spec/models/projects/project_acts_as_journalized_spec.rb` | T2 | D | `bin/rspec` green for both files |
| T9 | [ ] | op-tester | Contract specs: with `edit_project`, `subtitle` is writable; without it, write rejected / attribute not writable. Reuse `shared_contract_examples.rb` where applicable. Covers AC4(contract), scenario 7; FR-5/FR-6. | `spec/contracts/projects/update_contract_spec.rb`, `spec/contracts/projects/create_contract_spec.rb` | T3 | D | `bin/rspec` green; authorized writable, unauthorized rejected |
| T10 | [ ] | op-tester | API v3 request specs: **read** — show response includes `subtitle` as plain string (AC5, scenario 5, FR-7); **write** — authorized PATCH sets/clears subtitle and reads it back (AC6, scenario 6, FR-8/FR-9), `>255` → 422 with translated message (AC2 API side), unauthorized → 403/422 and value unchanged (AC4, scenario 7, FR-6). | `spec/requests/api/v3/projects/show_resource_spec.rb`, `spec/requests/api/v3/projects/update_resource_spec.rb` | T4 | D | `bin/rspec` green; read/write/limit/permission cases pass |
| T11 | [ ] | op-tester | Component spec: the subtitle renders as a **single-line plain-text** field (not a rich-text editor) with a **translated label**. Covers AC3, AC7; FR-3/FR-10. | `spec/components/projects/settings/general/show_component_spec.rb` | T6, T7 | D | `bin/rspec` green; field is `text_field`, label from i18n |
| T12 | [ ] | op-tester | Feature spec (Capybara/Cuprite): authorized user **sets, edits, and clears** the subtitle in general settings and it **persists across reload**; extend the settings page object. Covers AC1 (UI), scenarios 1–4; FR-5/FR-9. | `spec/features/projects/settings/general_settings_subtitle_spec.rb` (add), `spec/support/pages/projects/settings/general.rb` (edit) | T6, T7 | D | `bin/rspec` green with JS/feature tags; set/edit/clear persists |
| T13 | [ ] | op-tester | Copy spec: copying a project carries the `subtitle` to the copy (no code change — `subtitle` is not in `CopyService#skipped_attributes`; guards the "subtitle IS copied" Decision). | `spec/services/projects/copy_service_integration_spec.rb` | T2 | D | `bin/rspec` green; copied project has source subtitle |
| T14 | [ ] | op-reviewer | Final review: `rubocop` / `eslint` / `erb_lint` clean on the diff; `i18n-tasks` clean; confirm every spec.md acceptance criterion (AC1–AC7) maps to a passing tester task; confirm plan decisions honored (plain text not formattable, two-table migration, `edit_project` reuse, copy + journal behavior). | — (diff review) | T8, T9, T10, T11, T12, T13 | E | linters clean; all AC covered; no spec/plan deviations unflagged |

## Acceptance-criteria → task coverage

| Acceptance criterion (spec.md) | Covered by |
|---|---|
| AC1 — authorized user set/edit/clear in settings, persists | T8 (model), T12 (feature UI) |
| AC2 — >255 rejected w/ translated msg, 255 accepted | T8 (model), T10 (API 422) |
| AC3 — stored/rendered single-line plain text, separate from description | T8 (model), T11 (component) |
| AC4 — unauthorized cannot change via UI/API, value unchanged | T9 (contract), T10 (API 403/422) |
| AC5 — API v3 exposes subtitle for reading as plain text | T10 (show request) |
| AC6 — API v3 writable by authorized user, length+permission honored | T10 (update request) |
| AC7 — all labels/messages translatable, no hard-coded strings | T7 (i18n), T11 (component label) |

## Parallel groups

- **Group A** (no deps): T1 — migration.
- **Group B** (after A): T2, T3 — model then contract (T3 depends on T2; both backend, sequential within B).
- **Group C** (after B): **T4 (op-api) ∥ T5 (op-frontend) ∥ T7 (op-frontend i18n)** run in parallel; T6 follows T5 (same group, depends on the form object). API and frontend are independent.
- **Group D** (after C): **T8, T9, T10, T11, T12, T13** — all tester specs run in parallel.
- **Group E** (after D): T14 — final op-reviewer pass.

> Independent parallel work: in Group C, op-api (T4) and op-frontend (T5/T7) have no
> interdependency. In Group D all six tester tasks are independent and run concurrently.

## Notes / decisions during implementation

- `spec/services/projects/copy_service_spec.rb` (named in the plan) does not exist; the
  real project-copy spec is `spec/services/projects/copy_service_integration_spec.rb`
  (used in T13).
- No existing general-settings feature spec for this flow; T12 adds a new
  `general_settings_subtitle_spec.rb` and extends the existing
  `spec/support/pages/projects/settings/general.rb` page object.
- T4: payload writability and schema auto-derivation are "verify" steps — only edit the
  payload/schema representers if the request spec (T10) shows they are needed.
- <Append anything the agents discover that changes the plan.>
