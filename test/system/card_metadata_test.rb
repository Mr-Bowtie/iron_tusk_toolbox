require "application_system_test_case"

class CardMetadataTest < ApplicationSystemTestCase
  setup do
    @card_metadatum = card_metadata(:one)
  end

  test "visiting the index" do
    visit card_metadata_url
    assert_selector "h1", text: "Card metadata"
  end

  test "should create card metadatum" do
    visit card_metadata_url
    click_on "New card metadatum"

    fill_in "Mana cost", with: @card_metadatum.mana_cost
    fill_in "Name", with: @card_metadatum.name
    fill_in "Scryfall", with: @card_metadatum.scryfall_id
    fill_in "Tcgplayer", with: @card_metadatum.tcgplayer_id
    click_on "Create Card metadatum"

    assert_text "Card metadatum was successfully created"
    click_on "Back"
  end

  test "should update Card metadatum" do
    visit card_metadatum_url(@card_metadatum)
    click_on "Edit this card metadatum", match: :first

    fill_in "Mana cost", with: @card_metadatum.mana_cost
    fill_in "Name", with: @card_metadatum.name
    fill_in "Scryfall", with: @card_metadatum.scryfall_id
    fill_in "Tcgplayer", with: @card_metadatum.tcgplayer_id
    click_on "Update Card metadatum"

    assert_text "Card metadatum was successfully updated"
    click_on "Back"
  end

  test "should destroy Card metadatum" do
    visit card_metadatum_url(@card_metadatum)
    click_on "Destroy this card metadatum", match: :first

    assert_text "Card metadatum was successfully destroyed"
  end
end
