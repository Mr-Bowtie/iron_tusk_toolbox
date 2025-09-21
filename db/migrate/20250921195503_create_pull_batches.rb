class CreatePullBatches < ActiveRecord::Migration[7.2]
  def change
    create_table :pull_batches do |t|
      t.timestamps
      t.references :assigned_user, null: false, foreign_key: { to_table: :users }
      t.boolean :completed
    end
  end
end
