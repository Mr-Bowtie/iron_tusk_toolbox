require "rails_helper"
require "tempfile"

RSpec.describe Collection::DecklistImporters::Manabox do
  it "imports ManaBox CSV cards, aggregates by name and zone, and skips maybeboard rows" do
    decklist = Collection::Decklist.create!(name: "Rakdos Sacrifice", source_filename: "rakdos.csv", source_format: "manabox")
    file = Tempfile.new([ "rakdos", ".csv" ])
    file.write(<<~CSV)
      Name,Quantity,Board,Set code,Collector number,Foil
      Blood Artist,1,Mainboard,2X2,071,normal
      Blood Artist,2,Mainboard,JMP,206,foil
      Mayhem Devil,3,Sideboard,WAR,204,normal
      "Judith, the Scourge Diva",1,Commander,RNA,185,normal
      Claim the Firstborn,4,Maybeboard,ELD,118,normal
    CSV
    file.rewind

    described_class.call(file: file, decklist: decklist)

    cards = decklist.cards.order(:normalized_card_name, :zone)
    expect(cards.map { |card| [ card.card_name, card.normalized_card_name, card.quantity, card.zone, card.set_code, card.collector_number ] }).to eq([
      [ "Blood Artist", "blood artist", 3, "mainboard", "2X2", "071" ],
      [ "Judith, the Scourge Diva", "judith, the scourge diva", 1, "commander", "RNA", "185" ],
      [ "Mayhem Devil", "mayhem devil", 3, "sideboard", "WAR", "204" ]
    ])
    expect(cards.first.card_image_url).to eq("https://api.scryfall.com/cards/2x2/071?format=image&version=normal")
    expect(decklist.reload.card_count).to eq(7)
  ensure
    file&.close!
  end

  it "imports ManaBox text exports with section comments, printings, and foil markers" do
    decklist = Collection::Decklist.create!(name: "Sokka", source_filename: "sokka.txt", source_format: "manabox")
    file = Tempfile.new([ "sokka", ".txt" ])
    file.write(<<~TEXT)
      // COMMANDER
      1 Sokka, Tenacious Tactician (TLA) 242

      // DECK
      1 Ancestors' Aid (LCI) 132 *F*
      2 Arcane Denial (DRC) 70
      1 Eiganjo, Seat of the Empire (NEO) 268

      // MAYBEBOARD
      1 Claim the Firstborn (ELD) 118
    TEXT
    file.rewind

    described_class.call(file: file, decklist: decklist)

    cards = decklist.cards.order(:normalized_card_name, :zone)
    expect(cards.map { |card| [ card.card_name, card.normalized_card_name, card.quantity, card.zone, card.set_code, card.collector_number ] }).to eq([
      [ "Ancestors' Aid", "ancestors' aid", 1, "mainboard", "LCI", "132" ],
      [ "Arcane Denial", "arcane denial", 2, "mainboard", "DRC", "70" ],
      [ "Eiganjo, Seat of the Empire", "eiganjo, seat of the empire", 1, "mainboard", "NEO", "268" ],
      [ "Sokka, Tenacious Tactician", "sokka, tenacious tactician", 1, "commander", "TLA", "242" ]
    ])
    expect(decklist.reload.card_count).to eq(5)
  ensure
    file&.close!
  end
end
