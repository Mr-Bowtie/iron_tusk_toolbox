# == Schema Information
#
# Table name: inventory_cards
#
#  id          :bigint           not null, primary key
#  condition   :integer
#  foil        :boolean
#  quantity    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  manabox_id  :integer
#  scryfall_id :string
#
# Indexes
#
#  index_inventory_cards_on_scryfall_id_and_foil_and_condition  (scryfall_id,foil,condition) UNIQUE
#
require "test_helper"

class Inventory::CardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
