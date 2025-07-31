# == Schema Information
#
# Table name: orders
#
#  id                :bigint           not null, primary key
#  fees              :integer
#  fulfillment_data  :jsonb
#  items             :jsonb
#  marketplace_label :string
#  net_earned        :integer
#  placed_at         :date
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
      quantity = item["quantity"]
      inventory_card = Inventory::Card.where(
        scryfall_id: card["scryfall_id"],
        condition: Inventory::Card.map_condition(card["condition_id"]),
        foil: Inventory::Card.map_foil(card["finish_id"])
      )
      # TODO: surface error for not finding card
      unless inventory_card.empty?
        inventory_card.first.pull!(amount: quantity)
      else
        PullError.create(
          item_type: "card",
          message: "No matching inventory found for card",
          data: card
        )
      end
    end
  end

  def self.map_status(status)
    case status
    when "processing"
      "pulling"
    end
  end

  def update_and_sync_status(status)
  end
end
