class AddIndexToCardMetadata < ActiveRecord::Migration[7.2]
  def change
    add_index :card_metadata, :scryfall_id, unique: true
  end
end
