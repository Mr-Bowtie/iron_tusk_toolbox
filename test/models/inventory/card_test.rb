# == Schema Information
#
# Table name: inventory_cards
#
#  id                    :bigint           not null, primary key
#  condition             :integer
#  foil                  :boolean
#  quantity              :integer
#  staged                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  card_metadatum_id     :bigint
#  inventory_location_id :bigint
#  manabox_id            :integer
#  scryfall_id           :string
#
# Indexes
#
#  index_inventory_cards_on_card_metadatum_id                   (card_metadatum_id)
#  index_inventory_cards_on_inventory_location_id               (inventory_location_id)
#  index_inventory_cards_on_scryfall_id_and_foil_and_condition  (scryfall_id,foil,condition)
#
require "test_helper"

class Inventory::CardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
