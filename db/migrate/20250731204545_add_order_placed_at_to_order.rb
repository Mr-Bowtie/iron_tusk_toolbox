class AddOrderPlacedAtToOrder < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :placed_at, :date
  end
end
