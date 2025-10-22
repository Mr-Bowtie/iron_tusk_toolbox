# Repository Guidelines

## Project Structure & Module Organization
- `app/` contains the Rails MVC code, Stimulus controllers, and service objects; group business workflows under `app/services`.
- `lib/` holds reusable utilities and rake tasks.
- `spec/` covers RSpec service specs; `test/` keeps Minitest suites for models and system flows.
- `db/` keeps migrations, schema snapshots, and seeds; sample imports live in `example_data/`.
- Front-end assets originate in `app/assets` and `app/javascript`, with compiled bundles emitted to `app/assets/builds`.

## Build, Test & Development Commands
- Run `bin/setup` on first clone to install gems, Yarn dependencies, and bootstrap the database.
- Use `bin/dev` for day-to-day work; it launches the Rails server, GoodJob worker, and JS/CSS watchers from `Procfile.dev`.
- Compile assets with `yarn build` or `yarn build:css` before packaging releases or Docker images.
- Run `bin/rails db:migrate` for schema changes and `bin/rails db:reset` when local data drifts.

## Coding Style & Naming Conventions
- Ruby uses two-space indentation and Rails defaults; run `bin/rubocop` (Omakase config) before pushing.
- Name classes and modules with CamelCase, files with snake_case, and environment constants with SCREAMING_SNAKE_CASE.
- Place new service objects beneath `app/services/**/*_service.rb`; keep Stimulus controllers under `app/javascript/controllers`.
- JavaScript stays in ES modules; run `yarn build` often so esbuild flags issues early.

## Testing Guidelines
- Favor RSpec for new features (`bundle exec rspec`); name specs `*_spec.rb` and keep them close to the code.
- Maintain Minitest coverage with `bin/rails test`; model cases live in `test/models`, system flows in `test/system`.
- Reuse FactoryBot definitions in `test/factories`; pull realistic fixtures from `example_data/` when needed.
- Add regression specs for fixes and verify background jobs with GoodJob’s in-memory adapter.

## Commit & Pull Request Guidelines
- Adopt Conventional Commit prefixes (`feat:`, `fix:`, `chore:`) as seen in history; keep subjects under 72 characters.
- Squash noisy WIP commits before opening PRs and reference linked tickets or issue numbers.
- PR descriptions must list validation steps (`bin/rails test`, `bundle exec rspec`, `yarn build`) and include screenshots for UI changes.
- Request reviews from the owning team, ensure migrations roll back cleanly, and call out config or data migration impacts.

## Environment & Configuration Tips
- Load secrets via `.env` (dotenv-rails); never commit environment files or production credentials.
- Background jobs rely on GoodJob; confirm `config/database.yml` targets Postgres before running queues or `bin/dev`.
- Deployments use Docker and Fly.io (`Dockerfile`, `fly.toml`); mirror production with `docker-compose up` before promoting.
