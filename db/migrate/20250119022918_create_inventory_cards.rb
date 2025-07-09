class CreateInventoryCards < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_cards do |t|
      t.string :scryfall_id
      t.integer :manabox_id
      t.boolean :foil
      t.integer :condition
      t.integer :quantity

      t.timestamps
    end

    add_index :inventory_cards, [ :scryfall_id, :foil, :condition ]
  end
end
