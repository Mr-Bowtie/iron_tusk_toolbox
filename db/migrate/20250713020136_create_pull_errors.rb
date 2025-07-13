class CreatePullErrors < ActiveRecord::Migration[7.2]
  def change
    create_table :pull_errors do |t|
      t.timestamps
      t.text :message
      t.integer :item_type
      t.jsonb :data
    end
  end
end
