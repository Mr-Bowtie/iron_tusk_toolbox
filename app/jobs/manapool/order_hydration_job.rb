module Manapool
  class OrderHydrationJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      Manapool::OrderHydratorService.call(order_id)
    rescue => e
      Monitoring::Reporter.capture_exception(
        e,
        message: "ManaPool order hydration failed",
        tags: { job: "manapool.order_hydration" },
        extra: { order_id: order_id }
      )
    end
  end
end
