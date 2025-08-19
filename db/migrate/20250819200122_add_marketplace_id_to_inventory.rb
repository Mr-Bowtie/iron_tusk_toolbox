class AddMarketplaceIdToInventory < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_cards, :tcgplayer, :boolean
  end
end
