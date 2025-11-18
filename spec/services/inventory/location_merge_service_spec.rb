require "rails_helper"

RSpec.describe Inventory::LocationMergeService do
  let!(:source_location) { Inventory::Location.create!(label: "A1") }
  let!(:destination_location) { Inventory::Location.create!(label: "B1") }
  let!(:metadata_one) { CardMetadatum.create!(name: "Alpha", set: "SET", collector_number: "001") }
  let!(:metadata_two) { CardMetadatum.create!(name: "Beta", set: "SET", collector_number: "002") }

  describe "#merge!" do
    it "moves cards from the source to the destination and records their ids" do
      card_one = create_card(metadata_one, source_location)
      card_two = create_card(metadata_two, destination_location)

      merge = described_class.new(
        source_location: source_location,
        destination_location: destination_location
      ).merge!

      expect(merge.inventory_card_ids).to contain_exactly(card_one.id)
      expect(merge.destination_card_ids).to contain_exactly(card_two.id)
      expect(source_location.inventory_cards).to be_empty
      expect(destination_location.inventory_cards.pluck(:id)).to include(card_one.id, card_two.id)
    end

    it "raises an error when attempting to merge the same location" do
      create_card(metadata_one, source_location)

      service = described_class.new(source_location: source_location, destination_location: source_location)

      expect { service.merge! }.to raise_error(Inventory::LocationMergeService::MergeError)
    end

    it "raises an error when the source has no cards" do
      service = described_class.new(source_location: source_location, destination_location: destination_location)

      expect { service.merge! }.to raise_error(Inventory::LocationMergeService::MergeError)
    end
  end

  describe ".revert!" do
    it "moves back cards that still exist in the destination" do
      surviving_card = create_card(metadata_one, source_location)
      pulled_card = create_card(metadata_two, source_location)
      merge = described_class.new(
        source_location: source_location,
        destination_location: destination_location
      ).merge!

      Inventory::Card.find(pulled_card.id).destroy

      described_class.revert!(location_merge: merge)
      merge.reload

      expect(source_location.inventory_cards.pluck(:id)).to contain_exactly(surviving_card.id)
      expect(merge.reverted?).to be(true)
      expect(merge.reverted_card_count).to eq(1)
    end
  end

  def create_card(metadata, location)
    Inventory::Card.create!(
      metadata: metadata,
      inventory_location: location,
      quantity: 2,
      condition: :near_mint,
      foil: false,
      scryfall_id: SecureRandom.uuid
    )
  end
end
