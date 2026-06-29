class AddPrintingFieldsToCollectionCards < ActiveRecord::Migration[7.2]
  def change
    add_column :collection_cards, :set_code, :string
    add_column :collection_cards, :collector_number, :string
  end
end
