module Manapool
  class FetchOrdersService < ApplicationService
    def self.call(fulfilled:)
      last_shipped_order_time = Order.where(status: "shipped").order(placed_at: :desc).first&.placed_at&.utc&.iso8601
      # default to the beginning of epoch time if there is no previously shipped order in the system yet.
      last_shipped_order_time = Time.at(0).utc.iso8601 if last_shipped_order_time.nil?
      orders = nil
      if fulfilled == "all"
        orders = ManapoolClient.fetch_orders(fulfilled: true, since: last_shipped_order_time)
        orders += ManapoolClient.fetch_orders(fulfilled: false, since: last_shipped_order_time)
      else
        orders = ManapoolClient.fetch_orders(fulfilled: fulfilled, since: last_shipped_order_time)
      end
      orders.each do |order|
        Manapool::OrderHydrationJob.perform_later(order["id"])
      end
    end
  end
end

