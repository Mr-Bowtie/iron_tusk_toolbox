class CreateCardTags < ActiveRecord::Migration[7.2]
  def change
    create_table :card_tags do |t|
      t.timestamps
      t.belongs_to :card
      t.belongs_to :tag
    end
  end
end
