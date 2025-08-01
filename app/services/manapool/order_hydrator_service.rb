require "net/http"
require "open-uri"
require "uri"
require "json"
require "pry"

module Manapool
  class OrderHydratorService < ApplicationService
    def self.call(order_id)
      details = ManapoolClient.fetch_order_details(order_id)["order"]
      order = Order.find_or_initialize_by(marketplace_id: details["id"])
      binding.pry
      order.update(
        marketplace_label: details["label"],
        total_value: details["total_cents"],
        shipping_method: details["shipping_method"],
        items: details["items"],
        address_data: details["shipping_address"],
        source: "manapool", # TODO: change when other marketplaces added
        status: Order.map_status(details["latest_fulfillment_status"]),
        placed_at: details["created_at"]
      )
    end
  end
end
