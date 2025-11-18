class AddDestinationCardIdsToInventoryLocationMerges < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_location_merges, :destination_card_ids, :bigint, array: true, default: []
  end
end
