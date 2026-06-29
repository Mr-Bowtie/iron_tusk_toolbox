require "rails_helper"

RSpec.describe Collection::DecklistReportCreator do
  it "requires at least two decklists" do
    decklist = Collection::Decklist.create!(name: "Solo", source_filename: "solo.csv", source_format: "manabox")

    expect { described_class.call(decklists: [ decklist ]) }.to raise_error(Collection::DecklistReportCreator::ReportError, /at least two/i)
  end

  it "creates a persisted snapshot grouped by exact deck membership" do
    goblins = create_decklist("Goblins")
    rakdos = create_decklist("Rakdos Sacrifice")
    zombies = create_decklist("Dimir Zombies")

    create_card(goblins, "Sol Ring", 1, set_code: "LTC", collector_number: "279")
    create_card(rakdos, "Sol Ring", 1)
    create_card(zombies, "Sol Ring", 1)
    create_card(goblins, "Blood Artist", 1)
    create_card(rakdos, "Blood Artist", 2)
    create_card(zombies, "Gravecrawler", 4)

    report = described_class.call(decklists: [ goblins, rakdos, zombies ])

    expect(report).to be_persisted
    expect(report.selected_decklist_count).to eq(3)
    expect(report.unique_card_count).to eq(3)
    expect(report.shared_card_count).to eq(2)
    expect(report.decklists).to contain_exactly(goblins, rakdos, zombies)

    groups = report.snapshot.fetch("groups")
    expect(groups.map { |group| [ group.fetch("label"), group.fetch("cards").map { |card| card.fetch("name") } ] }).to eq([
      [ "All selected decklists", [ "Sol Ring" ] ],
      [ "Goblins + Rakdos Sacrifice", [ "Blood Artist" ] ],
      [ "Dimir Zombies only", [ "Gravecrawler" ] ]
    ])

    blood_artist = groups.second.fetch("cards").first
    expect(blood_artist.fetch("quantities")).to eq(goblins.id.to_s => 1, rakdos.id.to_s => 2)

    sol_ring = groups.first.fetch("cards").first
    expect(sol_ring.fetch("image_url")).to eq("https://api.scryfall.com/cards/ltc/279?format=image&version=normal")
  end

  def create_decklist(name)
    Collection::Decklist.create!(name: name, source_filename: "#{name.parameterize}.csv", source_format: "manabox")
  end

  def create_card(decklist, name, quantity, set_code: nil, collector_number: nil)
    decklist.cards.create!(
      card_name: name,
      normalized_card_name: name.strip.downcase,
      quantity: quantity,
      zone: "mainboard",
      set_code: set_code,
      collector_number: collector_number
    )
  end
end
