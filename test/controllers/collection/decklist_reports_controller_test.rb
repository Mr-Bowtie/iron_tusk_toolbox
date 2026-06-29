require "test_helper"

class Collection::DecklistReportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = FactoryBot.create(:user)
    sign_in @user
  end

  test "should create report from selected decklists and redirect to show" do
    decklist_one = Collection::Decklist.create!(name: "Goblins", source_filename: "goblins.csv", source_format: "manabox")
    decklist_two = Collection::Decklist.create!(name: "Rakdos", source_filename: "rakdos.csv", source_format: "manabox")
    decklist_one.cards.create!(card_name: "Sol Ring", normalized_card_name: "sol ring", quantity: 1, zone: "mainboard")
    decklist_two.cards.create!(card_name: "Sol Ring", normalized_card_name: "sol ring", quantity: 1, zone: "mainboard")

    assert_difference("Collection::DecklistReport.count", 1) do
      post collection_decklist_reports_url, params: { decklist_report: { decklist_ids: [ decklist_one.id, decklist_two.id ] } }
    end

    report = Collection::DecklistReport.last
    assert_redirected_to collection_decklist_report_url(report)
  end

  test "should create main deck overlap report and redirect to show" do
    main_decklist = Collection::Decklist.create!(name: "Goblins", source_filename: "goblins.csv", source_format: "manabox")
    comparison_decklist = Collection::Decklist.create!(name: "Rakdos", source_filename: "rakdos.csv", source_format: "manabox")
    main_decklist.cards.create!(card_name: "Sol Ring", normalized_card_name: "sol ring", quantity: 1, zone: "mainboard")
    comparison_decklist.cards.create!(card_name: "Sol Ring", normalized_card_name: "sol ring", quantity: 1, zone: "mainboard")

    assert_difference("Collection::DecklistReport.count", 1) do
      post collection_decklist_reports_url, params: {
        decklist_report: {
          report_type: "main_deck_overlap",
          main_decklist_id: main_decklist.id,
          comparison_decklist_ids: [ comparison_decklist.id ]
        }
      }
    end

    report = Collection::DecklistReport.last
    assert_equal "main_deck_overlap", report.snapshot.fetch("report_type")
    assert_redirected_to collection_decklist_report_url(report)
  end

  test "should show persisted report snapshot" do
    report = Collection::DecklistReport.create!(
      name: "Goblins + Rakdos",
      selected_decklist_count: 2,
      unique_card_count: 1,
      shared_card_count: 1,
      generated_at: Time.current,
      snapshot: {
        decklists: [ { id: 1, name: "Goblins", position: 1 }, { id: 2, name: "Rakdos", position: 2 } ],
        summary: { selected_decklist_count: 2, unique_card_count: 1, shared_card_count: 1 },
        groups: [ { decklist_ids: [ 1, 2 ], label: "All selected decklists", cards: [ { name: "Sol Ring", normalized_name: "sol ring", image_url: "https://api.scryfall.com/cards/ltc/279?format=image&version=normal", quantities: { "1" => 1, "2" => 1 } } ] } ]
      }
    )

    get collection_decklist_report_url(report)

    assert_response :success
    assert_includes response.body, "All selected decklists"
    assert_includes response.body, "Sol Ring"
    assert_select "img[src=?][alt=?]", "https://api.scryfall.com/cards/ltc/279?format=image&version=normal", "Sol Ring"
  end

  test "should show main deck overlap report context" do
    report = Collection::DecklistReport.create!(
      name: "Goblins overlap",
      selected_decklist_count: 2,
      unique_card_count: 1,
      shared_card_count: 1,
      generated_at: Time.current,
      snapshot: {
        report_type: "main_deck_overlap",
        main_decklist: { id: 1, name: "Goblins", position: 1 },
        comparison_decklists: [ { id: 2, name: "Rakdos", position: 2 } ],
        decklists: [ { id: 1, name: "Goblins", position: 1 }, { id: 2, name: "Rakdos", position: 2 } ],
        summary: { selected_decklist_count: 2, unique_card_count: 1, shared_card_count: 1 },
        groups: [ { decklist_ids: [ 1, 2 ], label: "Also in Rakdos", cards: [ { name: "Sol Ring", normalized_name: "sol ring", image_url: nil, quantities: { "1" => 1, "2" => 1 } } ] } ]
      }
    )

    get collection_decklist_report_url(report)

    assert_response :success
    assert_select "p", text: /Main deck:\s*Goblins/
    assert_includes response.body, "Also in Rakdos"
    assert_includes response.body, "Sol Ring"
  end

  test "should delete decklist report and report decklist links" do
    decklist = Collection::Decklist.create!(name: "Goblins", source_filename: "goblins.csv", source_format: "manabox")
    report = Collection::DecklistReport.create!(
      name: "Goblins report",
      selected_decklist_count: 1,
      unique_card_count: 1,
      shared_card_count: 0,
      generated_at: Time.current,
      snapshot: { groups: [] }
    )
    report.decklist_report_decklists.create!(decklist: decklist, decklist_name: decklist.name, source_filename: decklist.source_filename, position: 1)

    assert_difference("Collection::DecklistReport.count", -1) do
      assert_difference("Collection::DecklistReportDecklist.count", -1) do
        delete collection_decklist_report_url(report)
      end
    end

    assert_redirected_to collection_decklist_reports_url
  end
end
