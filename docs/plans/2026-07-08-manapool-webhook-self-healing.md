# ManaPool Webhook Self-Healing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure ManaPool keeps the canonical `order_created` webhook registered and that the callback URL passes ManaPool verification.

**Architecture:** First make `OrdersController#new_order_handler` accept verification requests without an `order` payload. Then add a ManaPool webhook registration client method, a small service that ensures the canonical webhook exists, and a recurring GoodJob cron job that runs that service.

**Tech Stack:** Rails 7, ActiveJob with GoodJob, Minitest, Net::HTTP

---

### Task 1: Accept ManaPool Verification Requests

**Files:**
- Modify: `app/controllers/orders_controller.rb`
- Test: `test/controllers/orders_controller_test.rb`

**Step 1: Write the failing test**

Add a controller test proving `POST /orders/new_order` with no `order` payload returns HTTP 200 and does not call the downstream ManaPool fetch or Matrix alert service.

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/orders_controller_test.rb`
Expected: FAIL because the action currently raises `ActionController::ParameterMissing`.

**Step 3: Write minimal implementation**

Guard `new_order_handler` so empty verification-style requests log and return `head :ok` before requiring `params[:order]`.

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/controllers/orders_controller_test.rb`
Expected: PASS for the new verification test.

### Task 2: Add ManaPool Webhook Sync Service

**Files:**
- Modify: `lib/manapool_client.rb`
- Create: `app/services/manapool/ensure_order_created_webhook_service.rb`
- Test: `test/services/manapool/ensure_order_created_webhook_service_test.rb`

**Step 1: Write the failing tests**

Add service tests proving:
- missing canonical webhook triggers registration
- existing canonical webhook skips registration

**Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/manapool/ensure_order_created_webhook_service_test.rb`
Expected: FAIL because the service/client registration path does not exist yet.

**Step 3: Write minimal implementation**

Add:
- `ManapoolClient.register_webhook(topic:, callback_url:)`
- support for `PUT` requests in `create_request`
- `Manapool::EnsureOrderCreatedWebhookService`

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/services/manapool/ensure_order_created_webhook_service_test.rb`
Expected: PASS

### Task 3: Add Recurring Job

**Files:**
- Create: `app/jobs/manapool/ensure_order_created_webhook_job.rb`
- Modify: `config/initializers/good_job.rb`
- Test: `test/jobs/manapool_ensure_order_created_webhook_job_test.rb`

**Step 1: Write the failing test**

Add a job test proving the job calls `Manapool::EnsureOrderCreatedWebhookService.call`.

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/manapool_ensure_order_created_webhook_job_test.rb`
Expected: FAIL because the job does not exist yet.

**Step 3: Write minimal implementation**

Create the job and register it in GoodJob cron on an hourly schedule.

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/jobs/manapool_ensure_order_created_webhook_job_test.rb`
Expected: PASS

### Task 4: Verify End-to-End

**Files:**
- No new files

**Step 1: Run targeted automated tests**

Run: `bin/rails test test/controllers/orders_controller_test.rb test/services/manapool/ensure_order_created_webhook_service_test.rb test/jobs/manapool_ensure_order_created_webhook_job_test.rb`
Expected: PASS

**Step 2: Run the sync service manually**

Run: `docker compose exec iron_tusk_toolbox bin/rails runner 'puts Manapool::EnsureOrderCreatedWebhookService.call'`
Expected: returns `true` if it had to register, `false` if already present.

**Step 3: Verify ManaPool webhook list**

Run: `docker compose exec iron_tusk_toolbox bin/rails runner 'pp ManapoolClient.fetch_webhooks'`
Expected: list includes the canonical `order_created` webhook.
