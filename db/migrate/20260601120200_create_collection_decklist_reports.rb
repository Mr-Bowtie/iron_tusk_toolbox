class CreateCollectionDecklistReports < ActiveRecord::Migration[7.2]
  def change
    create_table :collection_decklist_reports do |t|
      t.string :name, null: false
      t.integer :selected_decklist_count, null: false, default: 0
      t.integer :unique_card_count, null: false, default: 0
      t.integer :shared_card_count, null: false, default: 0
      t.jsonb :snapshot, null: false, default: {}
      t.datetime :generated_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :collection_decklist_reports, :generated_at
  end
end
