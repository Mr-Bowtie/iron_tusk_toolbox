# GlitchTip Monitoring Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand the app's existing GlitchTip integration to capture backend exceptions, structured logs, background job failures, and browser-side JavaScript errors.

**Architecture:** Keep GlitchTip as the single Sentry-compatible sink. Use `sentry-rails` and `@sentry/browser`, add a shared Ruby monitoring helper for rescued exceptions and log events, and inject browser config through layout meta tags.

**Tech Stack:** Rails 7.2, sentry-ruby, sentry-rails, esbuild, Stimulus, Turbo, Minitest, RSpec

---

### Task 1: Add failing backend monitoring tests

**Files:**
- Modify: `spec/config/glitchtip_config_spec.rb`
- Modify: `test/controllers/orders_controller_test.rb`
- Modify: `test/jobs/manapool_order_hydration_job_test.rb`
- Create: `test/lib/monitoring/reporter_test.rb`

**Step 1: Write the failing tests**

- Assert the Sentry initializer enables GlitchTip logs and logger breadcrumbs.
- Assert rescued webhook alert failures are reported to the monitoring helper.
- Assert `Manapool::OrderHydrationJob` reports rescued exceptions.
- Assert the shared monitoring helper captures exceptions and mirrors logs.

**Step 2: Run the targeted tests to verify they fail**

Run: `bundle exec rspec spec/config/glitchtip_config_spec.rb && bin/rails test test/controllers/orders_controller_test.rb test/jobs/manapool_order_hydration_job_test.rb test/lib/monitoring/reporter_test.rb`

Expected: failures for missing helper/config behavior.

**Step 3: Commit**

Commit message: `test: cover glitchtip monitoring integration`

### Task 2: Implement shared backend monitoring support

**Files:**
- Create: `lib/monitoring/reporter.rb`
- Modify: `config/application.rb`
- Modify: `config/initializers/sentry.rb`
- Modify: `app/controllers/application_controller.rb`
- Modify: `app/jobs/application_job.rb`

**Step 1: Write minimal implementation**

- Add a shared reporter API for `capture_exception` and `log`.
- Expand the Sentry initializer with `enable_logs`, low-volume defaults, and richer breadcrumbs.
- Set request/user/job context so captured events are searchable.

**Step 2: Run targeted backend tests**

Run: `bundle exec rspec spec/config/glitchtip_config_spec.rb && bin/rails test test/jobs/manapool_order_hydration_job_test.rb test/lib/monitoring/reporter_test.rb`

Expected: tests pass or fail only on remaining call sites.

**Step 3: Commit**

Commit message: `feat: add shared glitchtip monitoring support`

### Task 3: Patch rescued backend paths and key service boundaries

**Files:**
- Modify: `app/controllers/orders_controller.rb`
- Modify: `app/controllers/inventory/backups_controller.rb`
- Modify: `app/controllers/collection/decklists_controller.rb`
- Modify: `app/controllers/collection/decklist_reports_controller.rb`
- Modify: `app/controllers/inventory/location_merges_controller.rb`
- Modify: `app/jobs/manapool/order_hydration_job.rb`
- Modify: `app/jobs/scryfall_data_sync_job.rb`
- Modify: `app/services/scryfall_sync_service.rb`
- Modify: `lib/manapool_client.rb`
- Modify: `lib/matrix_http_client.rb`

**Step 1: Add monitoring calls**

- Report rescued exceptions with relevant IDs and payload context.
- Emit structured log messages at job starts/completions and external API failures.

**Step 2: Run controller/job tests**

Run: `bin/rails test test/controllers/orders_controller_test.rb test/jobs/manapool_order_hydration_job_test.rb`

Expected: passing tests and no regressions.

**Step 3: Commit**

Commit message: `feat: monitor rescued backend failures`

### Task 4: Add browser-side GlitchTip monitoring

**Files:**
- Modify: `package.json`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/javascript/application.js`
- Modify: `.env.glitchtip.erb`

**Step 1: Add the failing expectation**

- Extend config coverage to assert browser monitoring config is exposed in the layout or JS entrypoint.

**Step 2: Add the implementation**

- Install `@sentry/browser`.
- Initialize it early with DSN/env/release/sample rate from meta tags.
- Hook Stimulus error handling and enable browser logs.

**Step 3: Run the asset build**

Run: `yarn build`

Expected: exit code 0 and rebuilt assets.

**Step 4: Commit**

Commit message: `feat: add browser glitchtip monitoring`

### Task 5: Final verification and scan report

**Files:**
- Modify: `docs/plans/2026-07-07-glitchtip-monitoring-design.md`

**Step 1: Re-scan monitoring points**

- Confirm the highest-value rescue and integration boundaries are covered.

**Step 2: Run full verification**

Run:
- `bundle exec rspec spec/config/glitchtip_config_spec.rb`
- `bin/rails test test/controllers/orders_controller_test.rb test/jobs/manapool_order_hydration_job_test.rb test/lib/monitoring/reporter_test.rb`
- `yarn build`

Expected: all commands succeed.

**Step 3: Update the design doc if scan findings changed**

**Step 4: Commit**

Commit message: `docs: finalize glitchtip monitoring scan`
