require "rails_helper"

RSpec.describe Collection::MainDeckOverlapReportCreator do
  it "requires a main decklist" do
    comparison = create_decklist("Rakdos Sacrifice")

    expect { described_class.call(main_decklist: nil, comparison_decklists: [ comparison ]) }
      .to raise_error(Collection::MainDeckOverlapReportCreator::ReportError, /main deck/i)
  end

  it "requires at least one comparison decklist" do
    main = create_decklist("Goblins")

    expect { described_class.call(main_decklist: main, comparison_decklists: []) }
      .to raise_error(Collection::MainDeckOverlapReportCreator::ReportError, /comparison/i)
  end

  it "creates a persisted snapshot containing only cards from the main deck that overlap comparison decklists" do
    main = create_decklist("Goblins")
    rakdos = create_decklist("Rakdos Sacrifice")
    zombies = create_decklist("Dimir Zombies")

    create_card(main, "Sol Ring", 1, set_code: "LTC", collector_number: "279")
    create_card(main, "Blood Artist", 1)
    create_card(main, "Goblin Guide", 4)
    create_card(rakdos, "Sol Ring", 1)
    create_card(rakdos, "Blood Artist", 2)
    create_card(rakdos, "Village Rites", 4)
    create_card(zombies, "Sol Ring", 1)
    create_card(zombies, "Gravecrawler", 4)

    report = described_class.call(main_decklist: main, comparison_decklists: [ rakdos, zombies ])

    expect(report).to be_persisted
    expect(report.name).to eq("Goblins overlap")
    expect(report.selected_decklist_count).to eq(3)
    expect(report.unique_card_count).to eq(2)
    expect(report.shared_card_count).to eq(2)
    expect(report.decklists).to contain_exactly(main, rakdos, zombies)

    snapshot = report.snapshot
    expect(snapshot.fetch("report_type")).to eq("main_deck_overlap")
    expect(snapshot.fetch("main_decklist")).to include("id" => main.id, "name" => "Goblins")
    expect(snapshot.fetch("comparison_decklists").map { |decklist| decklist.fetch("name") }).to eq([ "Rakdos Sacrifice", "Dimir Zombies" ])

    groups = snapshot.fetch("groups")
    expect(groups.map { |group| [ group.fetch("label"), group.fetch("cards").map { |card| card.fetch("name") } ] }).to eq([
      [ "Also in Rakdos Sacrifice + Dimir Zombies", [ "Sol Ring" ] ],
      [ "Also in Rakdos Sacrifice", [ "Blood Artist" ] ]
    ])

    sol_ring = groups.first.fetch("cards").first
    expect(sol_ring.fetch("image_url")).to eq("https://api.scryfall.com/cards/ltc/279?format=image&version=normal")
    expect(sol_ring.fetch("quantities")).to eq(main.id.to_s => 1, rakdos.id.to_s => 1, zombies.id.to_s => 1)
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
