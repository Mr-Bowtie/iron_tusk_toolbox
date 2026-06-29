class CreateCollectionDecklists < ActiveRecord::Migration[7.2]
  def change
    create_table :collection_decklists do |t|
      t.string :name, null: false
      t.string :source_filename, null: false
      t.string :source_format, null: false, default: "manabox"
      t.string :game_format
      t.integer :card_count, null: false, default: 0
      t.datetime :uploaded_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :collection_decklists, :name
    add_index :collection_decklists, :source_format
  end
end
