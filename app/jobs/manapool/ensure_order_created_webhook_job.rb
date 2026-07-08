module Manapool
  class EnsureOrderCreatedWebhookJob < ApplicationJob
    queue_as :default

    def perform
      Manapool::EnsureOrderCreatedWebhookService.call
    rescue StandardError => e
      Monitoring::Reporter.capture_exception(
        e,
        message: "ManaPool order_created webhook sync failed",
        tags: { job: "manapool.ensure_order_created_webhook" }
      )
    end
  end
end
