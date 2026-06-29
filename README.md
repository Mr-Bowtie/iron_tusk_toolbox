# Iron Tusk Toolbox

Rails 7.2 app for running the Iron Tusk trading card workflow: manage inventory, import and fulfill ManaPool orders, and keep Magic card metadata fresh via Scryfall. Background work runs on GoodJob with PostgreSQL.

## Stack
- Ruby 3.2.6, Rails 7.2.2.1
- PostgreSQL (GoodJob shares the main database)
- Node 22.3.0 + Yarn 1.22 (esbuild + dart-sass, Bulma UI)
- Background jobs: GoodJob with cron (Scryfall sync scheduled daily at 02:00)

## Setup
1. Install prerequisites: Ruby 3.2.6, Bundler, PostgreSQL 15+, Node 22.3.0, Yarn 1.22.
2. Create `.env` (dotenv is loaded) with values for your machine. Example:
   ```
   RAILS_ENV=development
   RAILS_MASTER_KEY=your-master-key
   DB_HOST=localhost
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=postgres
   MANAPOOL_EMAIL=you@example.com
   MANAPOOL_AUTH_TOKEN=your-token
   ```
3. Install dependencies and prep the database:
   ```
   bin/setup
   ```
4. Optional: seed a default user (`test@test.com` / `password`) for local login:
   ```
   bin/rails db:seed
   ```

## Running locally
- Start everything (Rails server on 3000, JS/CSS watchers, GoodJob worker) with:
  ```
  bin/dev
  ```
- GoodJob dashboard: `/admin/jobs`
- Scryfall admin & manual sync controls: `/admin/scryfall`
- If you prefer manual processes, run `bundle exec rails server` and in another shell `bundle exec good_job start`.

## Data & background jobs
- **Scryfall metadata**: Cron job queues `ScryfallDataSyncJob` daily; first-run a manual sync from `/admin/scryfall` to populate `card_metadata`. Sync work fans out via `ScryfallBatchUpsertJob`, so keep the GoodJob worker running.
- **ManaPool orders**: Requires `MANAPOOL_EMAIL` and `MANAPOOL_AUTH_TOKEN`. Use the Orders page actions to fetch unfilled or all orders; hydration jobs pull line items before you generate pull sheets.
- **Inventory flows**: The root path `/inventory` exposes CSV import, staging, and pull workflows for store inventory.

## Tests & quality checks
- RSpec services and controllers: `bundle exec rspec`
- Minitest models/system tests: `bin/rails test`
- Style and security: `bundle exec rubocop`, `bundle exec brakeman`

### Running tests with Docker Compose

When the app is running through `docker compose`, prefer running tests inside the web container so Rails uses the same gemset and database wiring as the app:

```bash
docker compose exec iron_tusk_toolbox bundle exec rspec
docker compose exec iron_tusk_toolbox bin/rails test
```

For targeted runs:

```bash
docker compose exec iron_tusk_toolbox bundle exec rspec spec/services/collection/decklist_report_creator_spec.rb
docker compose exec iron_tusk_toolbox bin/rails test test/controllers/collection/decklists_controller_test.rb
```

If you need to run tests from the host shell while the Compose database is up, point Rails at the forwarded Postgres port instead of the default local socket/`localhost:5432`:

```bash
env DB_HOST=127.0.0.1 DB_PORT=5434 POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres bundle exec rspec
env DB_HOST=127.0.0.1 DB_PORT=5434 POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres bin/rails test
```

Prepare the test database against the Compose Postgres instance with:

```bash
env DB_HOST=127.0.0.1 DB_PORT=5434 POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres bin/rails db:prepare RAILS_ENV=test
```

## Assets
- Production builds: `yarn build` (JS, Pagy extras) and `yarn build:css` (Bulma/dart-sass). `bin/dev` runs both in watch mode.

## Database tasks
- Create/reset: `bin/rails db:prepare` (or `db:reset` to rebuild)
- Migrate: `bin/rails db:migrate`
- GoodJob also uses the primary database; run migrations before starting workers.

## Docker (optional)
- `docker compose up --build` uses `Dockerfile.development` and `docker-compose.yml` to run the app plus Postgres. Provide the same environment variables (including `RAILS_MASTER_KEY`) when starting the stack.
