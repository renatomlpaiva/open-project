# Spec: Project subtitle in the projects-list export

| | |
|---|---|
| **ID** | 004 |
| **Status** | approved |
| **Created** | 2026-06-15 |
| **Work package** | #____ (if any) |

## Problem / motivation

The project **subtitle** (an optional single-line plain-text value, ≤255 chars,
already stored, displayed and filterable) is a useful one-line description of a
project. Today, when a user exports the projects list, the subtitle is not
available in the export, so the exported data loses context that is visible in
the app. Users who export the projects list (e.g. for reporting or sharing)
should be able to get the subtitle alongside other project attributes such as
the project name, with no copy/paste from the UI.

## User scenarios

Written as Given / When / Then so they map directly to acceptance tests.

1. **Subtitle appears in the exported projects list**
   - **Given** a user is viewing the projects list and at least one project has a
     subtitle set
   - **When** the user exports the projects list (see Open questions re: format)
   - **Then** the export contains a "Subtitle" column, and for each project the
     subtitle value appears in that project's row, consistent with how the
     project **name** appears.

2. **Project without a subtitle exports an empty value**
   - **Given** a project has no subtitle set
   - **When** the user exports the projects list with the subtitle included
   - **Then** that project's subtitle cell is empty (no error, no placeholder
     text), just like an empty optional value in other columns.

3. **Subtitle with special characters is exported intact**
   - **Given** a project whose subtitle contains commas, double quotes, line
     breaks, or non-ASCII characters
   - **When** the user exports the projects list in a delimited format (e.g. CSV)
     with the subtitle included
   - **Then** the exported cell preserves the full subtitle value and the file
     remains correctly parseable (proper quoting/escaping per the export format),
     consistent with how existing text columns (e.g. name) are handled.

4. **Export visibility matches the projects list**
   - **Given** a user can only see a subset of projects in the projects list
     (per their permissions / visibility)
   - **When** they export the list including the subtitle
   - **Then** the export contains exactly the same projects (and their subtitles)
     that the user is allowed to see in the list — no extra projects, no
     subtitles for projects they cannot see.

## Functional requirements

Numbered, atomic, testable. Use MUST / SHOULD / MAY.

- **FR-1** When the projects list is exported and the subtitle is included in the
  export, the export MUST contain a dedicated subtitle column.
- **FR-2** The subtitle column header MUST use a localized, human-readable caption
  consistent with how the subtitle attribute is labelled elsewhere in the
  product (i.e. the same label used in the list / filter UI).
- **FR-3** For each exported project, the subtitle column MUST contain that
  project's current subtitle value exactly as stored.
- **FR-4** For a project with no subtitle, the subtitle cell MUST be empty
  (blank), not a placeholder, error, or literal "null".
- **FR-5** In delimited/text export formats (e.g. CSV), the subtitle value MUST be
  escaped/quoted so that special characters (commas, quotes, line breaks,
  separators, non-ASCII) do not corrupt the file, consistent with the escaping
  applied to existing text columns such as name.
- **FR-6** The set of projects (and therefore subtitles) included in the export
  MUST respect the same permission and visibility rules as the projects list
  itself; a user MUST NOT obtain subtitles for projects they cannot otherwise
  see.
- **FR-7** Subtitle export support MUST be added for the projects-list export
  format(s) the product already supports for the projects list (see Open
  questions for which exact formats are in scope: CSV and/or PDF; XLS is not
  currently offered for the projects list).
- **FR-8** Including the subtitle in the export MUST NOT change, remove, or
  reorder any existing export column; existing exports without subtitle selected
  MUST remain unchanged.
- **FR-9** A very long subtitle (up to the 255-character maximum) MUST be exported
  in full, without truncation.

## Out of scope

- Adding subtitle to the work-package export (this is about the **projects**
  list export only).
- Changing the subtitle attribute itself (length limit, validation, storage,
  display, or the existing subtitle filter).
- Adding any new export **format** that the projects list does not already
  support (e.g. introducing XLS/Excel export for projects).
- Rich text / multi-line subtitle, formatting, or translation of subtitle
  content.
- Changing the sort order or default selected columns of the projects list.

## Edge cases & error handling

- **No subtitle** → empty cell (FR-4), not an error.
- **Special characters** in CSV (commas, double quotes, semicolons, the
  configured CSV separator, line breaks) → value preserved and file stays valid
  (FR-5).
- **Non-ASCII / UTF-8** characters → preserved (the projects CSV already emits a
  UTF-8 BOM; subtitle must round-trip correctly).
- **Very long value** (up to 255 chars) → exported in full, no truncation (FR-9).
- **Empty projects list / no projects visible** → export still succeeds with the
  subtitle header present and zero data rows.
- **Permissions / visibility** → identical to the projects list (FR-6); archived
  projects follow the same rule as the rest of the export (admins may see them).
- **Format coverage** → behavior must be defined for each in-scope format; in a
  PDF export the subtitle should render as readable text in the corresponding
  cell/field (pending the format decision in Open questions).

## Acceptance criteria

The feature is "done" when:

- [ ] Exporting the projects list with subtitle included produces a column whose
  header is the localized subtitle label and whose cells hold each project's
  subtitle (FR-1, FR-2, FR-3) — verifies Scenario 1.
- [ ] A project with no subtitle yields an empty cell with no error (FR-4) —
  verifies Scenario 2.
- [ ] A subtitle containing commas, quotes, line breaks and non-ASCII characters
  exports into a valid, correctly-escaped file with the value intact (FR-5) —
  verifies Scenario 3.
- [ ] The exported project set matches the user's visible projects list under
  their permissions (FR-6) — verifies Scenario 4.
- [ ] Existing exports (without subtitle) are byte-for-byte unchanged in their
  existing columns (FR-8).
- [ ] A 255-character subtitle exports without truncation (FR-9).

## Decisions (resolved at spec gate, 2026-06-15)

- **Mechanism = make `subtitle` a selectable projects-list column** (option (a)). The export is column-driven, so adding `subtitle` to `Queries::Projects::Selects` is the prerequisite that makes it exportable — consistent with how `name`/`description` work. It then appears in the list (when the column is selected) and in the export. This is the real scope of feature 004.
- **Formats in scope: CSV and PDF** — the two the projects list already supports. **XLS is dropped** from scope (no projects XLS export exists; it would be net-new).
- **Column header/caption**: reuse the existing `Subtitle` label (`activerecord.attributes.project.subtitle`) — no new i18n.
- **View UI**: enabling `subtitle` as a selectable column in the projects-list view IS part of this feature (it is the mechanism by which the user adds it to the table and the export). The default selected columns are NOT changed (subtitle is opt-in).
