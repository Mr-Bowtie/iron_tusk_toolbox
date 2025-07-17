class CreateSyncStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :sync_statuses do |t|
      t.string :sync_type, null: false
      t.datetime :last_synced_at
      t.text :sync_details
      
      t.timestamps
      
      t.index :sync_type, unique: true
    end
  end
end