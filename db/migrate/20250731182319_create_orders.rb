class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.timestamps
      t.integer :source
      t.integer :status
      t.jsonb :items
      t.integer :total_value
      t.integer :fees
      t.integer :shipping_paid
      t.integer :net_earned
      t.string :shipping_method
      t.string :marketplace_id
      t.string :marketplace_label
      t.jsonb :fulfillment_data

    end
  end
end
