class AddCardBackImagesToMetadata < ActiveRecord::Migration[7.2]
  def change
    add_column :card_metadata, :front_image_uris, :jsonb, default: {}
    add_column :card_metadata, :back_image_uris, :jsonb, default: {}
  end
end
