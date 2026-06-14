<!--
  PLAN — the HOW. Maps the approved spec onto OpenProject's real architecture.
  Filled in by the `op-planner` agent via /plan. Reference concrete files/dirs so
  /tasks can split the work cleanly across agents. See AGENTS.md "Architecture".
-->

# Plan: <Feature title>

| | |
|---|---|
| **Spec** | ./spec.md |
| **Status** | draft \| approved |
| **Created** | YYYY-MM-DD |

## Approach summary

<2–5 sentences: the chosen approach and why, including any rejected alternative.>

## Affected layers

Check the layers this feature touches (drives which agents run):

- [ ] **Data model / migrations** — `db/migrate`, `app/models` → `op-backend`
- [ ] **Business logic** — `app/services` (ServiceResult), `app/contracts`, `app/policies` → `op-backend`
- [ ] **Module engine** — `modules/<name>/app/**` → `op-backend`
- [ ] **REST API v3** — `lib/api/v3/**` (Grape + roar representers) → `op-api`
- [ ] **Hotwire UI** — `app/components` (ViewComponent), `app/views`, `frontend/src/stimulus`, `frontend/src/turbo` → `op-frontend`
- [ ] **Legacy Angular** — `frontend/src/app/**` → `op-frontend`
- [ ] **Permissions / i18n** — `config/initializers/permissions*`, `config/locales` → owning agent

## Data model & migrations

<New tables/columns/indexes. Note OpenProject's migration conventions (see
docs/development/migrations/). State whether a data migration is needed.>

## Services & contracts

<Which Create/Update/Delete services and contracts to add or change. Confirm they
return ServiceResult and that authorization lives in a policy, not the service.>

## API (v3)

<New/changed Grape endpoints in lib/api/v3 and their representers. Reuse the same
services/contracts as the UI. Note HAL links/embeds.>

## Frontend

<Stimulus controllers / Turbo frames / ViewComponents (Primer) to add or change.
Only use Angular if extending existing SPA code. Note i18n keys.>

## Permissions

<New permissions, roles, and policy checks.>

## Test strategy

<Model/service/request/feature specs (RSpec) and Vitest specs. Which acceptance
criteria each covers. Note if feature specs need Capybara/Cuprite.>

## Risks & rollout

<Migration risk, performance, enterprise/BIM editions, feature flags, backwards compat.>

## File-level change map

| Path | Action | Notes |
|------|--------|-------|
| `app/services/.../create_service.rb` | add | ... |
| ... | ... | ... |
