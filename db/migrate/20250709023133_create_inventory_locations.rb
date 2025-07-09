class CreateInventoryLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_locations do |t|
      t.integer :position
      t.string :label
      t.timestamps
    end
  end
end
