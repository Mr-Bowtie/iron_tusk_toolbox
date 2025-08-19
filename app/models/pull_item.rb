# == Schema Information
#
# Table name: pull_items
#
#  id                    :bigint           not null, primary key
#  data                  :jsonb
#  inventory_type        :integer
#  quantity              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inventory_location_id :bigint           not null
#
# Indexes
#
#  index_pull_items_on_inventory_location_id  (inventory_location_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_location_id => inventory_locations.id)
#
class PullItem < ApplicationRecord
  belongs_to :inventory_location, class_name: "Inventory::Location"

  enum :inventory_type, [
    :card
  ]

  def undo!
    case inventory_type
    when "card"
      restore_card_inventory!
    else
      raise "Unsupported inventory category: #{inventory_category}"
    end

    destroy!
  end

  private

  def restore_card_inventory!
    inv_card = Inventory::Card.find_or_initialize_by(
      scryfall_id: data["scryfall_id"],
      foil: data["foil"],
      condition: data["condition"],
      inventory_location_id: inventory_location_id,
      tcgplayer: data["tcgplayer"]
    )

    inv_card.card_metadatum_id ||= data['card_metadatum_id']
    inv_card.quantity ||= 0
    inv_card.quantity += quantity
    inv_card.save!
  end
end
