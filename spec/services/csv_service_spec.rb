require "rails_helper"
require "tempfile"

RSpec.describe CsvService do
  describe ".process_streamed_csv" do
    it "merges duplicate manabox rows into a single staged inventory card" do
      scryfall_id = SecureRandom.uuid
      CardMetadatum.create!(
        name: "Test Card",
        set: "TST",
        collector_number: "1",
        scryfall_id: scryfall_id
      )

      csv = Tempfile.new([ "manabox-import", ".csv" ])
      csv.write(<<~CSV)
        Name,Set code,Set name,Collector number,Foil,Rarity,Quantity,ManaBox ID,Scryfall ID,Purchase price,Misprint,Altered,Condition,Language,Purchase price currency
        Test Card,TST,Test Set,1,normal,common,1,101,#{scryfall_id},0.10,false,false,Near Mint,en,USD
        Test Card,TST,Test Set,1,normal,common,2,102,#{scryfall_id},0.10,false,false,Near Mint,en,USD
      CSV
      csv.flush

      expect {
        described_class.process_streamed_csv(csv.path, InventoryImporter::Manabox, thread_count: 1, batch_size: 1)
      }.to change(Inventory::Card, :count).by(1)

      card = Inventory::Card.find_by!(scryfall_id: scryfall_id, foil: false, condition: "near_mint")
      expect(card.quantity).to eq(3)
      expect(card.staged).to be(true)
    ensure
      csv&.close!
    end
  end
end
