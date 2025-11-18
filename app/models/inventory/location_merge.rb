# == Schema Information
#
# Table name: inventory_location_merges
#
#  id                          :bigint           not null, primary key
#  destination_card_ids        :bigint           default([]), is an Array
#  inventory_card_ids          :bigint           default([]), is an Array
#  reverted_at                 :datetime
#  reverted_inventory_card_ids :bigint           default([]), is an Array
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  destination_location_id     :bigint           not null
#  source_location_id          :bigint           not null
#
# Indexes
#
#  index_inventory_location_merges_on_destination_location_id  (destination_location_id)
#  index_inventory_location_merges_on_source_location_id       (source_location_id)
#  index_location_merges_on_source_and_destination             (source_location_id,destination_location_id)
#
# Foreign Keys
#
#  fk_rails_...  (destination_location_id => inventory_locations.id)
#  fk_rails_...  (source_location_id => inventory_locations.id)
#
class Inventory::LocationMerge < ApplicationRecord
  belongs_to :source_location, class_name: "Inventory::Location"
  belongs_to :destination_location, class_name: "Inventory::Location"

  scope :recent_first, -> { order(created_at: :desc) }

  def moved_card_count
    inventory_card_ids&.length.to_i
  end

  def reverted_card_count
    reverted_inventory_card_ids&.length.to_i
  end

  def reverted?
    reverted_at.present?
  end
end
