# OpenProject AI Coding Agent Instructions

> **Note for developers**: You can create `AGENTS.local.md` (or `CLAUDE.local.md`) in this directory to add your own custom instructions or preferences for AI coding agents. These files are git-ignored and will not be committed to the repository.

## Repository Overview

**OpenProject** is a web-based, open-source project management software written in Ruby on Rails with PostgreSQL for data persistence.

- **Size**: Large monorepo (~840MB, ~1M+ lines of code)
- **Backend**: Ruby 3.4.7, Rails ~8.0.3
- **Frontend**: Node.js 22.22.3 or 24.15.0+, npm 10.9.8+, TypeScript
- **Database**: PostgreSQL (required)
- **Architecture**: Server-rendered HTML with Hotwire (Turbo + Stimulus). Legacy Angular components exist and are being migrated to custom elements. Uses GitHub's Primer Design System via ViewComponent.
- **Editions**: Community, Enterprise (SSO, LDAP, SCIM), and BIM (construction industry, code in `modules/bim/`)

> **Note**: The root `CLAUDE.md` is a symlink to this `AGENTS.md` (likewise in `app/` and `frontend/`). Edit `AGENTS.md`; both stay in sync. Read the nested `AGENTS.md` closest to the code you touch.

## Architecture (Big Picture)

These cross-cutting patterns require reading multiple files to grasp and recur across the whole app:

- **Modules are Rails engines.** Each subdirectory in `modules/` (e.g. `boards`, `costs`, `meeting`, `bim`) is a mountable engine with its own `app/`, `spec/`, and `config/`, wired in via `OpenProject::Plugins`. Enterprise features are gated at runtime, not split into a separate codebase.
- **Write paths go through service objects + contracts.** Mutations live in `app/services/**` (`*::CreateService`, `UpdateService`, …), return a `ServiceResult` (`app/services/service_result.rb`: success/failure + errors + result), and delegate validation to `app/contracts/**`. Some services model results with monads via `dry-monads`. Authorization is separate, in `app/policies/**` and the permission system. Keep business logic out of controllers and models.
- **The API is Grape, not Rails controllers.** The v3 REST API is defined in `lib/api/v3/**` with Grape; JSON is serialized by HAL representers (`roar`/representable), not Rails views. Endpoints reuse the same services/contracts as the HTML UI.
- **Two frontends coexist.** New UI is server-rendered HTML + Hotwire — Stimulus controllers in `frontend/src/stimulus/`, Turbo in `frontend/src/turbo/` — using Primer ViewComponents (`app/components/**`). Legacy SPA code is Angular in `frontend/src/app/`, exposed to server-rendered pages as Angular custom elements and being migrated away.
- **Background work uses Good Job.** Async jobs run through `good_job` (the `worker` process in `Procfile.dev`), backed by PostgreSQL.

## Critical Setup Requirements

**ALWAYS verify versions before building:**
- Ruby: `3.4.7` (see `.ruby-version`)
- Node: `^22.22.3 || ^24.15.0` (see `package.json` engines)
- Bundler: Latest 2.x

### Local Development Setup

```bash
bundle install                    # Install Ruby gems
cd frontend && npm ci && cd ..   # Install Node packages
bundle exec rails db:migrate      # Setup database
bin/dev                          # Start all services (Rails, frontend, Good Job worker)
# Access at http://localhost:3000
```

### Docker Development Setup

See [`docker/dev/AGENTS.md`](docker/dev/AGENTS.md) for full Docker setup and commands.

## Project Structure

### Key Directories

- `app/` — Rails application code
- `config/` — Rails configuration, routes, locales
- `db/` — Database migrations and seeds
- `docker/dev/` — Docker development environment
- `frontend/` — TypeScript/Angular/Stimulus frontend
- `lib/` — Ruby libraries and extensions
- `lookbook/` — ViewComponent previews (<https://qa.openproject-edge.com/lookbook/>)
- `modules/` — OpenProject plugin modules
- `spec/` — RSpec test suite

### Configuration Files

- `.ruby-version` - Ruby version
- `.rubocop.yml` - Ruby linting rules
- `.erb_lint.yml` - ERB template linting
- `frontend/eslint.config.mjs` - JavaScript/TypeScript linting
- `Gemfile` - Ruby dependencies
- `package.json` / `frontend/package.json` - Node.js dependencies
- `lefthook.yml` - Git hooks configuration

### Linting (Run Before Committing)

```bash
# Ruby
bundle exec rubocop                              # Check all files
bin/dirty-rubocop --uncommitted                  # Check only uncommitted changes

# JavaScript/TypeScript
cd frontend && npx eslint src/ && cd ..

# ERB Templates
erb_lint {files}

# Install Git Hooks (recommended)
bundle exec lefthook install
```

### Testing

```bash
# Backend (RSpec) — use bin/rspec (Spring-aware wrapper)
bin/rspec                                         # Full suite (slow)
bin/rspec spec/models/work_package_spec.rb        # Single file
bin/rspec spec/models/work_package_spec.rb:42     # Single example (by line number)
bin/rspec spec/features/                          # A directory
bin/rspec --seed 18352                            # Reproduce a CI ordering failure
CI=true bin/rspec ...                             # Eager-load app (match CI behavior)

# Feature/system specs use Capybara + Cuprite (headless Chrome by default)
OPENPROJECT_TESTING_NO_HEADLESS=1 bin/rspec spec/features/work_package_show_spec.rb

# Module specs live under each engine, e.g. modules/boards/spec/

# Frontend unit tests (Vitest, browser mode via Playwright) — run from frontend/
cd frontend && npm test            # Single run (ng test --watch=false)
cd frontend && npm run test:watch  # Watch mode
```

## Commit Messages
- First line: < 72 characters, then blank line, then detailed description
- Reference work packages when applicable
- Merge strategy: "Merge pull request" (not squash), except single-commit PRs can use "Rebase and merge"

## Additional Documentation

- `docs/development/` — Development documentation
- `docs/development/running-tests/` — Testing guide
- `docs/development/code-review-guidelines/` — Code review standards
- `CONTRIBUTING.md` — Contribution workflow
- `.github/copilot-instructions.md` — Extended agent instructions with troubleshooting
