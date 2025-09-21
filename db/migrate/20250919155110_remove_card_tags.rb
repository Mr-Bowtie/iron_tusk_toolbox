class RemoveCardTags < ActiveRecord::Migration[7.2]
  def change
    drop_table :card_tags
  end
end
