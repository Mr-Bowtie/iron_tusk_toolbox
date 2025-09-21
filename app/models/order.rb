# == Schema Information
#
# Table name: orders
#
#  id                :bigint           not null, primary key
#  address_data      :jsonb
#  fees              :integer
#  fulfillment_data  :jsonb
#  items             :jsonb
#  marketplace_label :string
#  net_earned        :integeir
#  placed_at         :datetime
#  shipping_method   :string
#  shipping_paid     :integer
#  source            :integer
#  status            :integer
#  total_value       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  marketplace_id    :string
#
class Order < ApplicationRecord
  enum :status, [ :unfulfilled, :pulling, :pulled, :shipped ]
  enum :source, [ :manapool, :tcgplayer ]

  # TODO: update this to work for sealed as well, and make this more generic with handlers for different markeplace objects
  def pull_items
    items.each do |item|
      card = item["product"]["single"]
      inventory_cards = InventoryFinder::Manapool.find_from_order_item(card)
      inventory_count = inventory_cards.sum(&:quantity)
      pull_count = item["quantity"]

      if inventory_cards.empty? || inventory_count == 0
        PullError.create!(
        message: "no Item found in inventory",
        item_type: "card",
        data: {
          name: card["name"],
          condition: card["condition_id"],
          foil: card["finish_id"],
          quantity: pull_count,
          set_code: card["set"],
          number: card["number"]
        }
        )
        next
      end

      if inventory_count < pull_count
        PullError.create!(
          message: "Insufficient inventory quantity. Requested: #{pull_count}, Found: #{inventory_count}",
          item_type: "card",
          data: {
            name: card["name"],
            condition: card["condition_id"],
            foil: card["foil_id"],
            quantity: pull_count,
            set_code: card["set"],
            number: card["number"]
          }
        )
        pull_count = inventory_count
      end


      while pull_count > 0
        active_item = inventory_cards.pop

        if active_item.quantity > pull_count
          active_item.pull!(amount: pull_count)
          pull_count = 0
        else
          pull_count -= active_item.quantity
          active_item.pull!(all_in_location: true)
        end
      end
    end
  end

  def self.map_status(status)
    case status
    when "processing"
      "pulling"
    when "shipped"
      "shipped"
    when nil
      "unfulfilled"
    end
  end
end
