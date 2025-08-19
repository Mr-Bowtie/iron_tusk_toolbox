module Manapool
  class OrderHydrationJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      Manapool::OrderHydratorService.call(order_id)
    rescue => e
      Rails.logger.error("[Manapool::OrderHydrationJob] Failed to hydrate order #{order_id}")
    end
  end
end
