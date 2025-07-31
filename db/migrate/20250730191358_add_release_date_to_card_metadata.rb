class AddReleaseDateToCardMetadata < ActiveRecord::Migration[7.2]
  def change
    add_column :card_metadata, :released_at, :date
  end
end
