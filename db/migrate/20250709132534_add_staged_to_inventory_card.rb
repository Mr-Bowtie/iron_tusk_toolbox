class AddStagedToInventoryCard < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_cards, :staged, :boolean
  end
end
