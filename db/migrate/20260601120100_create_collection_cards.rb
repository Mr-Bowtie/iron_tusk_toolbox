class CreateCollectionCards < ActiveRecord::Migration[7.2]
  def change
    create_table :collection_cards do |t|
      t.references :decklist, null: false, foreign_key: { to_table: :collection_decklists }
      t.string :card_name, null: false
      t.string :normalized_card_name, null: false
      t.integer :quantity, null: false, default: 1
      t.string :zone, null: false, default: "mainboard"
      t.string :game_format
      t.jsonb :raw_row, null: false, default: {}

      t.timestamps
    end

    add_index :collection_cards, [ :decklist_id, :normalized_card_name ]
    add_index :collection_cards, [ :decklist_id, :zone ]
  end
end
