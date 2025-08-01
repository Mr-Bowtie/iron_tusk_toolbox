module Manapool
  class FetchOrdersService < ApplicationService
    def self.call(unfulfilled: true)
      orders = ManapoolClient.fetch_orders(unfulfilled: unfulfilled)
      orders.each do |order|
        Manapool::OrderHydrationJob.perform_later(order["id"])
      end
    end
  end
end

