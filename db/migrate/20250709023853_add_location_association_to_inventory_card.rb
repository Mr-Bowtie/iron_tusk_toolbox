class AddLocationAssociationToInventoryCard < ActiveRecord::Migration[7.2]
  def change
    add_reference :inventory_cards, :inventory_location
  end
end
