class CreateCollectionDecklistReportDecklists < ActiveRecord::Migration[7.2]
  def change
    create_table :collection_decklist_report_decklists do |t|
      t.references :decklist_report, null: false, foreign_key: { to_table: :collection_decklist_reports }
      t.references :decklist, null: false, foreign_key: { to_table: :collection_decklists }
      t.string :decklist_name, null: false
      t.string :source_filename, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :collection_decklist_report_decklists,
              [ :decklist_report_id, :decklist_id ],
              name: "index_collection_report_decklists_on_report_and_decklist"
  end
end
