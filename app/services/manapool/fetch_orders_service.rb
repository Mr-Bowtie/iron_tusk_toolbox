module Manapool
  class FetchOrdersService < ApplicationService
    def self.call(unfulfilled: true)
      last_shipped_order_time = Order.where(status: "shipped").order(placed_at: :desc).first.placed_at.utc.iso8601
      orders = ManapoolClient.fetch_orders(unfulfilled: unfulfilled, since: last_shipped_order_time)
      orders.each do |order|
        Manapool::OrderHydrationJob.perform_later(order["id"])
      end
    end
  end
end

