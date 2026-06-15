<!--
  SPEC — the WHAT and WHY of a feature. NO implementation details (no file names,
  no class names, no framework choices). Filled in by the `op-spec-writer` agent
  via /specify. Keep it testable: every requirement should be verifiable.
-->

# Spec: Filter projects list by subtitle

| | |
|---|---|
| **ID** | 003 |
| **Status** | approved |
| **Created** | 2026-06-15 |
| **Work package** | (none) |

## Problem / motivation

Projects now carry an optional single-line **subtitle** (a short tagline), stored, exposed in API v3, editable in settings, and shown read-only in lists and the project overview (features 001 and 002). However, users cannot yet *find* projects by that subtitle: the projects list can be filtered by name, identifier, status, parent, and other attributes, but not by subtitle. As subtitles become a common place to record a short summary (e.g. a team, client, or program label), users want to narrow the projects list to those whose subtitle matches given text — the same way they already filter by project **name**. The filter must work in both the projects-list filter UI and the API v3 project query filters, so that scripts, dashboards, and saved views behave consistently with the interactive list.

## User scenarios

Written as Given / When / Then so they map directly to acceptance tests.

1. **Filter the list to subtitles containing text**
   - **Given** several projects, some with a subtitle containing the text "alpha" and some without
   - **When** a user filters the projects list by subtitle with a "contains" value of "alpha"
   - **Then** the list shows only the projects the user may see whose subtitle contains "alpha" (and excludes all others)

2. **Filter via the API v3 project query**
   - **Given** an API client requesting projects with a subtitle filter (contains "alpha") via API v3
   - **When** the request is executed
   - **Then** the response contains the same set of projects that the UI subtitle filter would return for that user, honoring visibility

3. **Subtitle filter is offered in the filter UI**
   - **Given** a user viewing the projects-list filter controls
   - **When** they open the list of available filters
   - **Then** "subtitle" appears as a selectable, translatable filter alongside the existing name filter

4. **No matching projects**
   - **Given** no visible project has a subtitle matching the entered value
   - **When** the user applies the subtitle filter
   - **Then** the list renders an empty result (no error), and the API returns an empty collection

5. **Case-insensitive matching (consistent with name)**
   - **Given** a project whose subtitle is "Logistics Hub"
   - **When** a user filters by subtitle containing "logistics"
   - **Then** that project is included, regardless of letter case

6. **Visibility is respected**
   - **Given** a project whose subtitle matches the filter value but which the requesting user is not allowed to see
   - **When** the user applies the subtitle filter (UI or API)
   - **Then** that project is NOT returned

7. **UI / API parity**
   - **Given** the same filter value and the same user
   - **When** the subtitle filter is applied once through the UI and once through API v3
   - **Then** both produce the same set of projects

## Functional requirements

Numbered, atomic, testable. Use MUST / SHOULD / MAY.

- **FR-1** The project query/filter system MUST provide a **subtitle** filter that narrows the projects list to projects whose subtitle matches a given text value.
- **FR-2** The subtitle filter MUST support a "contains" (substring) text match, behaving consistently with the existing project **name** filter for the equivalent operator.
- **FR-3** Subtitle text matching MUST be case-insensitive, consistent with how the project name filter matches text.
- **FR-4** The subtitle filter MUST be available in the projects-list filter UI as a selectable filter, presented with a translatable label (no hard-coded UI text).
- **FR-5** The subtitle filter MUST be available through the API v3 project query filters, using a stable, documented filter key.
- **FR-6** Applying the subtitle filter MUST return identical result sets for the same user and value whether invoked via the UI or via API v3 (parity).
- **FR-7** The subtitle filter MUST respect the same project visibility/permission rules as the rest of the projects list: a project the user may not see MUST NOT appear in filtered results, even if its subtitle matches.
- **FR-8** When no visible project matches the filter value, the system MUST return an empty result set without error in both the UI and the API.
- **FR-9** The set of supported operators MUST be defined explicitly and applied identically in UI and API. [see Open questions — which operators]
- **FR-10** Projects with no subtitle (empty/unset) MUST NOT match a "contains" value, and MUST be handled correctly by any "is empty"-style operator if such an operator is supported. [see Open questions — operators]
- **FR-11** The subtitle filter MUST NOT alter the result ordering, paging, or other filters applied to the projects list; it only constrains which projects are included.

## Out of scope

- **Sorting / ordering** the projects list by subtitle (this spec only adds filtering).
- **Full-text search / relevance ranking** of subtitles (only simple substring/text matching as used by the name filter; no scoring, stemming, or weighting).
- Editing, validating, or storing the subtitle, and displaying it in settings, lists, or the overview — already delivered by features 001 and 002.
- Adding the subtitle to global/quick search, work-package filters, or any list other than the projects list.
- Highlighting or emphasizing the matched substring within the displayed subtitle.
- Filtering by subtitle in any non-v3 / legacy API.

## Edge cases & error handling

- **Empty filter value**: a "contains" filter with an empty/blank value — behavior must be defined (treated as no-op / matches all, or rejected); MUST NOT error. [see Open questions]
- **No matches**: empty result, not an error, in both UI and API (FR-8).
- **Case sensitivity**: matching is case-insensitive (FR-3); verify with mixed-case subtitle and query.
- **Projects with no subtitle**: excluded from "contains" matches (FR-10); included/excluded correctly by "is empty"-style operators if supported.
- **Visibility / permissions**: matching but non-visible projects are excluded (FR-7); an admin and a limited user filtering on the same value can see different result sets, each correct for their visibility.
- **API parity with UI**: same value + same user ⇒ same results (FR-6); filter key and operator names are stable and documented.
- **Special characters in the value**: text containing characters meaningful to the underlying match (e.g. `%`, `_`, quotes, Unicode) MUST be matched as literal user text and MUST NOT cause errors or injection. [see Open questions — literal vs. wildcard handling]
- **Whitespace in the value**: leading/trailing whitespace and multi-word values behave consistently with the name filter's equivalent operator. [see Open questions — multi-word "**" behavior]
- **Multibyte / Unicode subtitles**: matching works on character content, consistent with how name matching handles Unicode.

## Acceptance criteria

The feature is "done" when:

- [ ] A subtitle "contains" filter narrows the projects list to projects whose subtitle contains the value, case-insensitively (FR-1, FR-2, FR-3; scenarios 1, 5).
- [ ] The subtitle filter appears as a selectable, translatable option in the projects-list filter UI (FR-4; scenario 3).
- [ ] The subtitle filter is usable via API v3 project query filters with a stable key (FR-5; scenario 2).
- [ ] UI and API v3 return identical result sets for the same user and value (FR-6; scenario 7).
- [ ] Projects the user may not see never appear in filtered results, even when their subtitle matches (FR-7; scenario 6).
- [ ] No matching projects yields an empty result with no error in both UI and API (FR-8; scenario 4).
- [ ] Projects with no subtitle are excluded from "contains" matches (FR-10).
- [ ] The supported operator set (resolved from Open questions) is implemented identically in UI and API (FR-9).

## Decisions (resolved at spec gate, 2026-06-15)

Guiding principle: **mirror the existing project `name` filter exactly** for consistency.

- **Operators**: same set as the name filter — contains `~`, does-not-contain `!~`, is `=`, is-not `!`, and the token `**` search. No more, no less.
- **"is empty" / "is not empty"**: NOT offered (parity with the name filter; keeps scope tight).
- **Case sensitivity**: case-insensitive (same `LOWER(...) LIKE` matching as name).
- **Empty filter value**: same behavior as the name filter (no special-casing).
- **Special characters** (`%`, `_`): treated as literal text, exactly like the name filter.
- **Scope**: projects list query only — not the typeahead/global project pickers.
