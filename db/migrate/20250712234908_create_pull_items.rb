class CreatePullItems < ActiveRecord::Migration[7.2]
  def change
    create_table :pull_items do |t|
      t.integer :inventory_type
      t.integer :quantity, null: false
      t.references :inventory_location, null: false, foreign_key: { to_table: :inventory_locations }
      t.jsonb :data
      t.timestamps
    end
  end
end
