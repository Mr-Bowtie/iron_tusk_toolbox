class AddShippingInfoToOrder < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :address_data, :jsonb
  end
end
