require "test_helper"

class Collection::DecklistsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = FactoryBot.create(:user)
    sign_in @user
  end

  test "should get index" do
    get collection_decklists_url

    assert_response :success
    assert_includes response.body, "Collection Decklists"
  end

  test "report generation form should not include delete method inputs" do
    Collection::Decklist.create!(name: "Goblins", source_filename: "goblins.csv", source_format: "manabox")
    Collection::Decklist.create!(name: "Rakdos", source_filename: "rakdos.csv", source_format: "manabox")

    get collection_decklists_url

    report_form = css_select("form[action='#{collection_decklist_reports_path}']").first
    assert report_form, "expected report generation form"
    assert_empty report_form.css("input[name='_method'][value='delete']"), "delete controls must not inject DELETE into report generation form"
  end

  test "should upload ManaBox decklist using filename as default name" do
    file = Tempfile.new([ "goblins", ".csv" ])
    file.write(<<~CSV)
      Name,Quantity,Board
      Goblin Guide,4,Mainboard
    CSV
    file.rewind

    upload = Rack::Test::UploadedFile.new(file.path, "text/csv", original_filename: "goblins.csv")

    assert_difference("Collection::Decklist.count", 1) do
      post collection_decklists_url, params: { decklist: { csv: upload } }
    end

    decklist = Collection::Decklist.last
    assert_equal "goblins", decklist.name
    assert_equal "goblins.csv", decklist.source_filename
    assert_redirected_to collection_decklist_url(decklist)
  ensure
    file&.close!
  end

  test "should upload ManaBox text decklist using filename as default name" do
    file = Tempfile.new([ "sokka", ".txt" ])
    file.write(<<~TEXT)
      // COMMANDER
      1 Sokka, Tenacious Tactician (TLA) 242

      // DECK
      1 Arcane Denial (DRC) 70
    TEXT
    file.rewind

    upload = Rack::Test::UploadedFile.new(file.path, "text/plain", original_filename: "sokka.txt")

    assert_difference("Collection::Decklist.count", 1) do
      post collection_decklists_url, params: { decklist: { file: upload } }
    end

    decklist = Collection::Decklist.last
    assert_equal "sokka", decklist.name
    assert_equal "sokka.txt", decklist.source_filename
    assert_equal 2, decklist.card_count
    assert_redirected_to collection_decklist_url(decklist)
  ensure
    file&.close!
  end

  test "should show imported card images from set and collector number" do
    decklist = Collection::Decklist.create!(name: "Goblins", source_filename: "goblins.csv", source_format: "manabox")
    decklist.cards.create!(card_name: "Goblin Guide", quantity: 4, zone: "mainboard", set_code: "2X2", collector_number: "071")

    get collection_decklist_url(decklist)

    assert_response :success
    assert_select "img[src=?][alt=?]", "https://api.scryfall.com/cards/2x2/071?format=image&version=normal", "Goblin Guide"
    assert_includes response.body, "2X2"
    assert_includes response.body, "071"
  end

  test "should delete decklist and its imported cards" do
    decklist = Collection::Decklist.create!(name: "Goblins", source_filename: "goblins.csv", source_format: "manabox")
    decklist.cards.create!(card_name: "Goblin Guide", quantity: 4, zone: "mainboard")

    assert_difference("Collection::Decklist.count", -1) do
      assert_difference("Collection::Card.count", -1) do
        delete collection_decklist_url(decklist)
      end
    end

    assert_redirected_to collection_decklists_url
  end
end
