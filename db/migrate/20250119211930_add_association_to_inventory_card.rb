class AddAssociationToInventoryCard < ActiveRecord::Migration[7.2]
  def change
    add_reference :inventory_cards, :card_metadatum
  end
end
