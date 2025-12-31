# == Schema Information
#
# Table name: pull_batches
#
#  id               :bigint           not null, primary key
#  completed        :boolean          default(FALSE)
#  label            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  assigned_user_id :bigint           not null
#
# Indexes
#
#  index_pull_batches_on_assigned_user_id  (assigned_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_user_id => users.id)
#
require "test_helper"

class PullBatchTest < ActiveSupport::TestCase
  test "destroy reverts pull items and restores inventory cards" do
    location = FactoryBot.create(:inventory_location)
    metadata = FactoryBot.create(:card_metadatum)
    pull_batch = FactoryBot.create(:pull_batch, completed: true)
    pull_item = FactoryBot.create(
      :pull_item,
      pull_batches_id: pull_batch.id,
      inventory_location: location,
      card_metadatum: metadata,
      quantity: 3
    )

    assert_difference("PullItem.count", -1) do
      assert_difference("Inventory::Card.count", 1) do
        pull_batch.send(:revert_pull_items)
      end
    end

    inv_card = Inventory::Card.find_by(
      scryfall_id: metadata.scryfall_id,
      foil: false,
      condition: "near_mint",
      inventory_location_id: location.id,
      tcgplayer: false
    )
    assert_equal 3, inv_card.quantity
    assert_nil PullItem.find_by(id: pull_item.id)
  end

  test "destroy increases quantity on existing inventory cards" do
    location = FactoryBot.create(:inventory_location)
    metadata = FactoryBot.create(:card_metadatum)
    inventory_card = FactoryBot.create(
      :inventory_card,
      inventory_location: location,
      metadata: metadata,
      scryfall_id: metadata.scryfall_id,
      foil: false,
      condition: "near_mint",
      quantity: 2,
      tcgplayer: false
    )
    pull_batch = FactoryBot.create(:pull_batch, completed: true)
    FactoryBot.create(
      :pull_item,
      pull_batches_id: pull_batch.id,
      inventory_location: location,
      card_metadatum: metadata,
      quantity: 4
    )

    pull_batch.send(:revert_pull_items)

    assert_equal 6, inventory_card.reload.quantity
  end

  test "revert_pull_items does nothing when batch is not completed" do
    location = FactoryBot.create(:inventory_location)
    metadata = FactoryBot.create(:card_metadatum)
    pull_batch = FactoryBot.create(:pull_batch, completed: false)
    pull_item = FactoryBot.create(
      :pull_item,
      pull_batches_id: pull_batch.id,
      inventory_location: location,
      card_metadatum: metadata,
      quantity: 2
    )

    inventory_count = Inventory::Card.count
    pull_item_count = PullItem.count

    pull_batch.send(:revert_pull_items)

    assert_equal inventory_count, Inventory::Card.count
    assert_equal pull_item_count, PullItem.count
    assert_not_nil PullItem.find_by(id: pull_item.id)
  end
end
