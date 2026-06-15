<!--
  SPEC — the WHAT and WHY of a feature. NO implementation details (no file names,
  no class names, no framework choices). Filled in by the `op-spec-writer` agent
  via /specify. Keep it testable: every requirement should be verifiable.
-->

# Spec: Display project subtitle

| | |
|---|---|
| **ID** | 002 |
| **Status** | approved |
| **Created** | 2026-06-15 |
| **Work package** | (none) |

## Problem / motivation

Feature 001 added an optional, single-line plain-text **subtitle** to projects (≤255 characters, stored, exposed in API v3, and editable in project settings). Today that subtitle is only visible inside project settings and via the API — readers browsing the application never see it. The whole point of a subtitle is to give people immediate context about a project right where they encounter its name. This feature surfaces the subtitle read-only in the two places the project name appears prominently — the projects list/index and the project header/overview — so the short tagline is visible without opening settings or calling the API.

## User scenarios

Written as Given / When / Then so they map directly to acceptance tests.

1. **Subtitle shown in the projects list**
   - **Given** a project that has a subtitle and a user allowed to see that project in the projects list
   - **When** the user views the projects list/index
   - **Then** the project's subtitle is displayed read-only together with (beneath or beside) the project name

2. **Subtitle shown in the project header/overview**
   - **Given** a project that has a subtitle and a user allowed to view that project
   - **When** the user opens the project header/overview area where the project name is shown prominently
   - **Then** the project's subtitle is displayed read-only near the project name

3. **No subtitle present — projects list**
   - **Given** a project that has no subtitle (empty/unset)
   - **When** the user views the projects list/index
   - **Then** only the project name is shown — no empty row, blank line, label, or placeholder is rendered for the subtitle

4. **No subtitle present — header/overview**
   - **Given** a project that has no subtitle (empty/unset)
   - **When** the user opens the project header/overview
   - **Then** only the project name is shown — no empty space, label, or placeholder is rendered for the subtitle

5. **Display only — no editing affordance**
   - **Given** any user viewing the projects list or the project header/overview
   - **When** they look at the displayed subtitle
   - **Then** the subtitle is rendered as static read-only text with no inline edit control; editing remains only in project settings

6. **Special characters are rendered safely**
   - **Given** a project whose subtitle contains HTML-like characters (e.g. `<b>`, `&`, `"`) or other markup-looking text
   - **When** the subtitle is displayed in the list or header/overview
   - **Then** the characters are shown as literal text and are not interpreted as markup or executable content

7. **Visibility follows the project name**
   - **Given** a user who is NOT allowed to see a given project (so the project name is not shown to them in the list or header/overview)
   - **When** that project would otherwise appear
   - **Then** the subtitle is likewise not shown — the subtitle is visible to exactly the audience that can already see the project name in that surface, and never reveals a hidden project

## Functional requirements

Numbered, atomic, testable. Use MUST / SHOULD / MAY.

- **FR-1** The system MUST display the project's subtitle, read-only, in the projects list/index, associated with the project name (beneath or beside it).
- **FR-2** The system MUST display the project's subtitle, read-only, in the project header/overview area where the project name is shown prominently.
- **FR-3** The subtitle MUST be shown only when it is present (non-empty). When a project has no subtitle, no row, label, separator, or placeholder for the subtitle MUST be rendered in either surface.
- **FR-4** The displayed subtitle MUST be read-only in these surfaces: no inline editing, no edit affordance. Editing remains exclusively in project settings.
- **FR-5** The subtitle MUST be displayed using the same visibility and permission rules that govern showing the project name in that surface; it MUST NOT be shown to a user who cannot see the project there, and MUST NOT cause an otherwise hidden project to become visible.
- **FR-6** The subtitle MUST be rendered as plain text with all characters escaped/neutralized so that HTML, script, or other markup-looking content is shown literally and cannot be interpreted or executed.
- **FR-7** The subtitle MUST be rendered as a single line consistent with its stored single-line plain-text nature (it is not rich text).
- **FR-8** Any new user-facing label, tooltip, or accessibility text introduced for the subtitle display MUST use translatable strings (no hard-coded UI text). The subtitle value itself is user-entered content and is shown verbatim (not translated).
- **FR-9** The subtitle display MUST reflect the current stored value, including showing an updated value after the subtitle is changed in settings and showing nothing after it is cleared.
- **FR-10** The subtitle display MUST be visually distinguishable from / subordinate to the project name (i.e. it reads as a secondary tagline, not as part of the name itself or as the project description).

## Out of scope

- Editing the subtitle from the list or header/overview (editing remains in project settings only).
- Filtering, sorting, grouping, or searching projects by subtitle.
- Adding the subtitle as a configurable/selectable column in the projects list query, or to saved project views/queries. [see Open questions]
- Showing the subtitle in surfaces other than the projects list/index and the project header/overview (e.g. breadcrumbs, global search results, work package views, project cards elsewhere, dashboards, emails, exports). [see Open questions]
- Changing how the subtitle is stored, validated, or exposed via the API (covered by feature 001).
- Changing the project name, description, or status display.
- Any change to who may view a project (this feature only follows existing visibility).

## Edge cases & error handling

- **No subtitle present**: nothing rendered; no empty/placeholder element, no extra spacing or label (FR-3; scenarios 3, 4).
- **Whitespace-only subtitle**: treated as no subtitle for display purposes (feature 001 stores whitespace-only input as empty), so nothing is rendered. [confirm consistency with 001]
- **Very long subtitle (up to 255 chars)**: MUST display without breaking the layout of the list row or the header/overview. Whether long values are truncated (e.g. with an ellipsis and full text available via tooltip/title) or wrapped is a design decision. [see Open questions]
- **HTML / script / markup-like characters in value**: rendered as literal escaped text, never interpreted (FR-6; scenario 6).
- **Multibyte / Unicode / RTL characters**: displayed correctly, consistent with how the project name is displayed.
- **Permissions / visibility**: subtitle visible to exactly the audience that can see the project name in that surface; never exposes a project the user cannot see (FR-5; scenario 7).
- **Archived projects**: where an archived project's name is shown (e.g. in the list with the archived label), the subtitle follows the same showing rules as the name. [see Open questions]
- **i18n**: any introduced labels/accessibility strings appear via translation keys and render in non-English locales; the subtitle content itself is shown verbatim.
- **Real-time / stale display**: after the subtitle is edited or cleared in settings, the next render of the list/header/overview reflects the current value (FR-9).

## Acceptance criteria

The feature is "done" when:

- [ ] A project with a subtitle shows it read-only beneath/beside its name in the projects list/index (FR-1, FR-4; scenario 1).
- [ ] A project with a subtitle shows it read-only in the project header/overview area (FR-2, FR-4; scenario 2).
- [ ] A project without a subtitle shows no subtitle element, label, or placeholder in either surface (FR-3; scenarios 3, 4).
- [ ] The displayed subtitle is escaped/plain text — markup-like content renders as literal text and cannot execute (FR-6; scenario 6).
- [ ] The subtitle is shown only to users who can already see the project name in that surface, and never reveals a hidden project (FR-5; scenario 7).
- [ ] The subtitle renders as a single-line secondary tagline, visually subordinate to the name (FR-7, FR-10).
- [ ] Updating or clearing the subtitle in settings is reflected on the next render of both surfaces (FR-9).
- [ ] Any introduced labels/accessibility text use translation keys; no hard-coded UI strings (FR-8).

## Decisions (resolved at spec gate, 2026-06-15)

- **Truncation**: long subtitles render on a single line, truncated with an ellipsis, with the full text available via the native `title` tooltip (both surfaces).
- **Header/overview target**: the project **Overview page** heading area (where the project name is shown prominently). Not the sidebar/menu header or breadcrumb.
- **Projects list**: rendered as **secondary text inline beneath the project name** (not a separate toggleable query column).
- **Mobile/responsive**: shown and truncated (same behavior); no special hiding.
- **Archived projects**: the subtitle IS shown wherever the (archived-labeled) name is shown.
- **Accessibility**: plain adjacent secondary text (no special `aria-describedby` association required).
- **Other surfaces** (breadcrumbs, global search, project cards): out of scope for now — only the projects list and the project Overview heading.
