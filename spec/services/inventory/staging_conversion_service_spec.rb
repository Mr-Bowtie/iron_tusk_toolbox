require "rails_helper"

RSpec.describe Inventory::StagingConversionService do
  it "merges staged quantity into an existing live card in the selected location" do
    metadata = CardMetadatum.create!(
      name: "Test Card",
      set: "TST",
      collector_number: "1",
      scryfall_id: SecureRandom.uuid
    )
    location = Inventory::Location.create!(label: "A1")
    live_card = Inventory::Card.create!(
      metadata: metadata,
      inventory_location: location,
      scryfall_id: metadata.scryfall_id,
      foil: false,
      condition: :near_mint,
      quantity: 5,
      staged: false
    )
    staged_card = Inventory::Card.create!(
      metadata: metadata,
      scryfall_id: metadata.scryfall_id,
      foil: false,
      condition: :near_mint,
      quantity: 2,
      staged: true
    )

    expect {
      described_class.call(
        staged_cards: Inventory::Card.where(id: staged_card.id),
        location: location,
        tcgplayer: "0"
      )
    }.to change(Inventory::Card, :count).by(-1)

    expect(live_card.reload.quantity).to eq(7)
    expect(Inventory::Card.exists?(staged_card.id)).to be(false)
  end

  it "allows the same card key to exist in multiple live inventory locations" do
    metadata = CardMetadatum.create!(
      name: "Test Card",
      set: "TST",
      collector_number: "1",
      scryfall_id: SecureRandom.uuid
    )
    location_one = Inventory::Location.create!(label: "A1")
    location_two = Inventory::Location.create!(label: "B1")

    Inventory::Card.create!(
      metadata: metadata,
      inventory_location: location_one,
      scryfall_id: metadata.scryfall_id,
      foil: false,
      condition: :near_mint,
      quantity: 1,
      staged: false
    )

    expect {
      Inventory::Card.create!(
        metadata: metadata,
        inventory_location: location_two,
        scryfall_id: metadata.scryfall_id,
        foil: false,
        condition: :near_mint,
        quantity: 1,
        staged: false
      )
    }.to change(Inventory::Card, :count).by(1)
  end
end
