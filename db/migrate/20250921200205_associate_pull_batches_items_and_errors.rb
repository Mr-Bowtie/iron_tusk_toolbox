class AssociatePullBatchesItemsAndErrors < ActiveRecord::Migration[7.2]
  def change
    add_reference :pull_items, :pull_batches
    add_reference :pull_errors, :pull_batches
    add_column :pull_items, :pulled, :boolean
  end
end
