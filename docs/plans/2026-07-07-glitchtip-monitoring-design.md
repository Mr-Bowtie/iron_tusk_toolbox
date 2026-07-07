# GlitchTip Monitoring Design

**Date:** 2026-07-07

## Goal

Expand the app's existing Sentry-compatible GlitchTip setup so it captures:

- Rails request exceptions and context
- rescued backend failures that are currently only logged
- background job execution and failures
- browser-side JavaScript errors from Turbo/Stimulus
- structured operational logs sent directly to GlitchTip

## Current State

The app already includes `sentry-ruby` and `sentry-rails`, ships a basic initializer in `config/initializers/sentry.rb`, and documents a DSN template in `.env.glitchtip.erb`. Production logs go to STDOUT. Several failure paths rescue exceptions and only emit `Rails.logger.error`, which means GlitchTip misses those failures unless they are re-raised.

## Recommended Approach

Use the existing Sentry SDKs as the only monitoring path and point them at GlitchTip.

### Server-side

- Expand the Rails Sentry initializer to enable GlitchTip-compatible structured logs and better defaults for a low-volume private app.
- Add request context and user context in `ApplicationController`.
- Add a shared monitoring helper that:
  - captures rescued exceptions with tags and extra context
  - emits structured operational logs to GlitchTip
  - mirrors those events to the existing Rails logger
- Use that helper in rescued controller actions, jobs, and key service/client boundaries.

### Browser-side

- Add `@sentry/browser` to the existing esbuild pipeline.
- Initialize it early in `app/javascript/application.js`.
- Read DSN/environment/release/sample-rate settings from Rails-rendered meta tags in the main layout.
- Capture global browser errors automatically and hook Stimulus error handling so controller failures are visible in GlitchTip.

## Key Monitoring Locations

### Existing rescued failures

- `app/controllers/orders_controller.rb`
- `app/controllers/inventory/backups_controller.rb`
- `app/controllers/collection/decklists_controller.rb`
- `app/controllers/collection/decklist_reports_controller.rb`
- `app/controllers/inventory/location_merges_controller.rb`
- `app/jobs/manapool/order_hydration_job.rb`
- `app/jobs/scryfall_data_sync_job.rb`

### External integration boundaries

- `lib/manapool_client.rb`
- `lib/matrix_http_client.rb`
- `app/services/scryfall_sync_service.rb`
- `app/services/matrix_alerts/new_order_service.rb`
- `app/services/manapool/*`

### Operational flows worth logging

- incoming webhooks
- job start/finish/failure
- external API request failures
- inventory restore/import failures
- long-running Scryfall sync milestones

## Tradeoffs

- Enabling logs increases event volume, but this app's usage is low and the added visibility is worth it.
- Browser monitoring exposes DSN values to the client, which is standard for Sentry-compatible browser SDKs.
- Source maps are not being added in this pass because GlitchTip sourcemap workflows are separate deployment work; the first step is capturing the failures at all.

## Testing

- Config spec coverage for new Sentry/GlitchTip options
- unit coverage for the shared monitoring helper
- controller/job regression tests for rescued-exception capture behavior
- JS build verification after adding the browser SDK
