class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.integer :kind
      t.string :value

      t.timestamps
    end
  end
end
