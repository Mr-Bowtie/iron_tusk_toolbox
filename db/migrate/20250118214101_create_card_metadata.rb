class CreateCardMetadata < ActiveRecord::Migration[7.2]
  def change
    create_table :card_metadata do |t|
      t.string :scryfall_id
      t.integer :tcgplayer_id
      t.string :name
      t.string :mana_cost
      t.integer :cmc
      t.string :type_line
      t.string :oracle_text
      t.string :power
      t.string :toughness
      t.string :colors, array: true, default: []
      t.string :color_identity, array: true, default: []
      t.string :keywords: array: true, default: []
      t.jsonb :legalities, default: {}
      t.string :frame_effects, array: true, default: []
      t.string :layout
      t.string :produced_mana, array: true, default: []
      t.string :set
      t.string :set_name
      t.string :collector_number
      t.string :rarity


      t.timestamps
    end
  end
end
