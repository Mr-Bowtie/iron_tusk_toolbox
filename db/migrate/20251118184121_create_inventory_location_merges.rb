class CreateInventoryLocationMerges < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_location_merges do |t|
      t.references :source_location, null: false, foreign_key: { to_table: :inventory_locations }
      t.references :destination_location, null: false, foreign_key: { to_table: :inventory_locations }
      t.bigint :inventory_card_ids, array: true, default: []
      t.bigint :reverted_inventory_card_ids, array: true, default: []
      t.datetime :reverted_at

      t.timestamps
    end

    add_index :inventory_location_merges, [ :source_location_id, :destination_location_id ], name: "index_location_merges_on_source_and_destination"
  end
end
