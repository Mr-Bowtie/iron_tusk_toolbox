# ManaPool Webhook Self-Healing Design

## Goal

Keep the `order_created` ManaPool webhook registered against `https://toolbox.batb.love/orders/new_order`, and make the webhook endpoint tolerate ManaPool's registration verification requests so the registration does not get disabled again immediately.

## Approach

The current webhook intake path works for real order payloads but rejects requests that do not include `params[:order]`. ManaPool's webhook registration endpoint verifies the callback URL before accepting it, and that verification currently receives HTTP 400 from `OrdersController#new_order_handler`. The fix has two parts:

1. Make `POST /orders/new_order` return HTTP 200 for verification-style requests that omit the `order` payload.
2. Add an explicit ManaPool webhook registration client path, a service that ensures the canonical `order_created` webhook exists, and a recurring GoodJob cron entry that re-registers it when missing.

## Components

- `app/controllers/orders_controller.rb`
  - Accept empty verification requests and log them.
  - Preserve the existing order-fetch + Matrix alert behavior for real webhook payloads.
- `lib/manapool_client.rb`
  - Add `PUT /api/v1/webhooks/register` support with the correct JSON body:
    - `topic`
    - `callback_url`
  - Harden webhook fetch/register error handling with monitoring logs.
- `app/services/manapool/ensure_order_created_webhook_service.rb`
  - Treat `https://toolbox.batb.love/orders/new_order` as the canonical callback.
  - Detect whether the canonical `order_created` webhook is already registered.
  - Register it only when absent.
- `app/jobs/manapool/ensure_order_created_webhook_job.rb`
  - Run the service on a schedule.
  - Report success/failure through `Monitoring::Reporter`.
- `config/initializers/good_job.rb`
  - Add a cron entry for the recurring self-healing job.

## Data Flow

1. GoodJob runs `Manapool::EnsureOrderCreatedWebhookJob` on a cron schedule.
2. The job calls `Manapool::EnsureOrderCreatedWebhookService`.
3. The service fetches current webhooks from ManaPool.
4. If no webhook matches:
   - `topic == "order_created"`
   - `callback_url == "https://toolbox.batb.love/orders/new_order"`
   then it registers the webhook through `PUT /api/v1/webhooks/register`.
5. ManaPool verifies the callback URL.
6. `OrdersController#new_order_handler` returns HTTP 200 even when the verification request has no `order` payload.

## Error Handling

- Verification requests without `params[:order]` should return `head :ok` and not attempt order sync or Matrix alerting.
- Webhook fetch/register failures should log useful context and raise in the client layer.
- The recurring job should capture exceptions to monitoring without crashing the process.

## Testing

- Controller test:
  - verification request without `order` payload returns HTTP 200 and does not invoke downstream services.
- Service tests:
  - registers the canonical webhook when missing.
  - skips registration when the canonical webhook is already present.
- Job test:
  - delegates to the service.
- Verification:
  - run targeted controller/job/service tests.
  - run the service once manually and confirm ManaPool reports the webhook as registered.
