<!--
  SPEC — the WHAT and WHY of a feature. NO implementation details (no file names,
  no class names, no framework choices). Filled in by the `op-spec-writer` agent
  via /specify. Keep it testable: every requirement should be verifiable.
-->

# Spec: Project subtitle

| | |
|---|---|
| **ID** | 001 |
| **Status** | approved |
| **Created** | 2026-06-14 |
| **Work package** | (none) |

## Problem / motivation

A project today has a one-line **name** and a rich-text **description**. There is no concise, single-line way to summarize what a project is about: the name is constrained (it doubles as an identifier-like label and is often kept short/formal), while the description is long-form rich text that is too heavy to surface in lists, headers, or cards. Teams want a short tagline — a "subtitle" — that gives readers immediate context without opening the full description. Exposing it in the API also lets external tools and dashboards display this summary consistently.

## User scenarios

Written as Given / When / Then so they map directly to acceptance tests.

1. **Set a subtitle in project settings**
   - **Given** a user who is allowed to manage a project's settings, viewing that project's general settings
   - **When** they enter a short single-line subtitle and save
   - **Then** the subtitle is persisted and shown on the settings page afterwards

2. **Edit an existing subtitle**
   - **Given** a project that already has a subtitle and a user allowed to manage its settings
   - **When** they change the subtitle text and save
   - **Then** the new value replaces the old one

3. **Clear a subtitle**
   - **Given** a project that has a subtitle and a user allowed to manage its settings
   - **When** they remove the text and save
   - **Then** the subtitle becomes empty and the project is still valid

4. **Subtitle is optional**
   - **Given** a project being created or edited with no subtitle entered
   - **When** the project is saved
   - **Then** the save succeeds and the project has no subtitle

5. **Read the subtitle via the API**
   - **Given** an API client requesting a project that has a subtitle
   - **When** it fetches that project resource via API v3
   - **Then** the response includes the subtitle value as plain text

6. **Write the subtitle via the API**
   - **Given** an API client authenticated as a user allowed to manage the project
   - **When** it sends an update setting the subtitle field via API v3
   - **Then** the subtitle is persisted and returned on subsequent reads

7. **Permission denied**
   - **Given** a user who can view a project but is NOT allowed to manage its settings
   - **When** they attempt to change the subtitle (via UI or API)
   - **Then** the change is rejected and the existing value is unchanged

## Functional requirements

Numbered, atomic, testable. Use MUST / SHOULD / MAY.

- **FR-1** A project MUST support an optional **subtitle** attribute that is a single line of free text.
- **FR-2** The subtitle MUST be limited to a maximum of 255 characters; values longer than 255 characters MUST be rejected with a validation error.
- **FR-3** The subtitle MUST be plain text and single-line — it MUST NOT support rich-text formatting, and it is distinct from the existing project description.
- **FR-4** The subtitle MUST be optional: a project MUST be creatable and saveable with the subtitle empty or unset.
- **FR-5** A user who is allowed to manage the project (project settings) MUST be able to set, change, and clear the subtitle through the project settings.
- **FR-6** A user who is NOT allowed to manage the project MUST NOT be able to change the subtitle; the system MUST reject such attempts and leave the stored value unchanged.
- **FR-7** The subtitle MUST be readable through the API v3 project resource as a plain-text value.
- **FR-8** The subtitle MUST be writable through the API v3 for users authorized to manage the project, and the same 255-character and permission rules MUST apply as in the UI.
- **FR-9** Clearing the subtitle (setting it to empty) MUST be a valid operation and MUST result in no subtitle on the project.
- **FR-10** All user-facing labels and validation messages introduced for the subtitle MUST use translatable strings (no hard-coded UI text).
- **FR-11** Leading/trailing whitespace MUST be trimmed and embedded line breaks MUST be stripped so the subtitle stays a single line; whitespace-only input is treated as empty (cleared).

## Out of scope

- Rich-text / multi-line formatting for the subtitle (it is plain, single-line text).
- Showing the subtitle in project lists, headers, cards, breadcrumbs, or other surfaces beyond project settings and the API. [see Open questions — may be desired later]
- Filtering, sorting, or full-text searching projects by subtitle.
- Including the subtitle in project journals / change history (versioning of the field).
- Localizing or translating the subtitle content itself (the stored value is user-entered free text).
- Adding the subtitle to project copy/template behavior beyond default attribute handling. [see Open questions]
- Migrating or backfilling subtitles from existing description content.

## Edge cases & error handling

- **Empty input**: no subtitle entered → save succeeds; field is absent/blank everywhere it is exposed.
- **Whitespace-only input**: treated as empty (subject to FR-11 / Open questions).
- **Exactly 255 characters**: accepted.
- **256+ characters**: rejected with a clear, translated validation error in both UI and API.
- **Multibyte / Unicode characters**: the 255 limit MUST be applied consistently (character count, not bytes), matching how other single-line project text limits are enforced. [see Open questions]
- **Newlines / line breaks pasted in**: input MUST remain single-line (line breaks rejected, stripped, or collapsed — to be decided). [see Open questions]
- **Permission denied (UI and API)**: change rejected; stored value untouched; appropriate error/forbidden response.
- **i18n**: labels and error messages appear via translation keys and render correctly for non-English locales.
- **API parity**: the field behaves identically (validation, permission, optionality) whether edited via UI or API v3; reading and writing use a consistent field name and plain-text type.
- **HTML/script in value**: arbitrary text including HTML-like characters is stored as plain text and rendered safely (escaped) wherever displayed.

## Acceptance criteria

The feature is "done" when:

- [ ] An authorized user can set, edit, and clear a project subtitle from project settings and the value persists (FR-1, FR-4, FR-5, FR-9; scenarios 1–4).
- [ ] A subtitle longer than 255 characters is rejected with a translated validation message; exactly 255 is accepted (FR-2, FR-10; edge cases).
- [ ] The subtitle is stored and rendered as single-line plain text, separate from the description (FR-3).
- [ ] An unauthorized user cannot change the subtitle via UI or API; the stored value is unchanged (FR-6; scenario 7).
- [ ] The API v3 project resource exposes the subtitle for reading as plain text (FR-7; scenario 5).
- [ ] The subtitle can be written via API v3 by an authorized user, honoring the length and permission rules (FR-8; scenario 6).
- [ ] All introduced labels and messages are translatable, with no hard-coded UI strings (FR-10).

## Decisions (resolved at spec gate, 2026-06-14)

- **Field name**: `subtitle` (UI label and API v3 property).
- **Length unit**: 255 **characters** (not bytes), mirroring the project `name` length validation.
- **Whitespace/newline**: trim leading/trailing whitespace and strip embedded line breaks to keep it single-line; whitespace-only input is treated as empty/cleared (see FR-11).
- **Permission scope**: gated by the existing `edit_project` permission (project general settings) — no new permission.
- **Project copy/templates**: the subtitle IS copied along with other project attributes.
- **Additional display surfaces** (lists/headers/cards): deferred / out of scope for now; the API field leaves it available for future use.
- **Change history**: subtitle changes ARE tracked in the project journal, consistent with the description.
