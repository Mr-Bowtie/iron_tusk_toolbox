# GlitchTip Structured Request and SQL Logging Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add richer request and SQL structured logging to GlitchTip for the Rails app.

**Architecture:** Replace the default Sentry Rails structured log subscribers with app-specific subscribers that emit better request and SQL attributes, and feed SQL logs with request context from a request-scoped store set in `ApplicationController`.

**Tech Stack:** Rails 7.2, sentry-ruby, sentry-rails, ActiveSupport notifications, RSpec

---

### Task 1: Add failing specs for custom structured log subscribers

**Files:**
- Create: `spec/lib/monitoring/log_subscribers/action_controller_subscriber_spec.rb`
- Create: `spec/lib/monitoring/log_subscribers/active_record_subscriber_spec.rb`
- Modify: `spec/config/glitchtip_config_spec.rb`

**Step 1: Write the failing test**

Add specs asserting:

- controller events emit request method, path, status, request id, and timing attributes
- SQL events emit statement name, duration, cache state, DB metadata, and request linkage
- the Sentry initializer uses the app-specific subscribers

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/config/glitchtip_config_spec.rb spec/lib/monitoring/log_subscribers/action_controller_subscriber_spec.rb spec/lib/monitoring/log_subscribers/active_record_subscriber_spec.rb`
Expected: FAIL because the custom subscriber classes and initializer wiring do not exist yet

**Step 3: Write minimal implementation**

Deferred to later tasks.

**Step 4: Run test to verify it passes**

Deferred to later tasks.

### Task 2: Add request context and custom subscribers

**Files:**
- Create: `lib/monitoring/request_context.rb`
- Create: `lib/monitoring/log_subscribers/action_controller_subscriber.rb`
- Create: `lib/monitoring/log_subscribers/active_record_subscriber.rb`
- Modify: `app/controllers/application_controller.rb`
- Modify: `config/initializers/sentry.rb`

**Step 1: Write the failing test**

Covered by Task 1.

**Step 2: Run test to verify it fails**

Covered by Task 1.

**Step 3: Write minimal implementation**

Add:

- a request-scoped context store
- controller request context setup/reset
- custom Sentry log subscribers for request and SQL events
- initializer wiring to replace the stock Sentry subscribers

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/config/glitchtip_config_spec.rb spec/lib/monitoring/log_subscribers/action_controller_subscriber_spec.rb spec/lib/monitoring/log_subscribers/active_record_subscriber_spec.rb`
Expected: PASS

### Task 3: Syntax and diff verification

**Files:**
- Modify: none

**Step 1: Run syntax checks**

Run: `ruby -c app/controllers/application_controller.rb && ruby -c config/initializers/sentry.rb && ruby -c lib/monitoring/request_context.rb && ruby -c lib/monitoring/log_subscribers/action_controller_subscriber.rb && ruby -c lib/monitoring/log_subscribers/active_record_subscriber.rb`
Expected: all report `Syntax OK`

**Step 2: Inspect final diff**

Run: `git diff -- app/controllers/application_controller.rb config/initializers/sentry.rb lib/monitoring/request_context.rb lib/monitoring/log_subscribers/action_controller_subscriber.rb lib/monitoring/log_subscribers/active_record_subscriber.rb spec/config/glitchtip_config_spec.rb spec/lib/monitoring/log_subscribers/action_controller_subscriber_spec.rb spec/lib/monitoring/log_subscribers/active_record_subscriber_spec.rb`
Expected: only monitoring-related files changed
