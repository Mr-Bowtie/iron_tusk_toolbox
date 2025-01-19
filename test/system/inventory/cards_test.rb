require "application_system_test_case"

class Inventory::CardsTest < ApplicationSystemTestCase
  setup do
    @inventory_card = inventory_cards(:one)
  end

  test "visiting the index" do
    visit inventory_cards_url
    assert_selector "h1", text: "Cards"
  end

  test "should create card" do
    visit inventory_cards_url
    click_on "New card"

    click_on "Create Card"

    assert_text "Card was successfully created"
    click_on "Back"
  end

  test "should update Card" do
    visit inventory_card_url(@inventory_card)
    click_on "Edit this card", match: :first

    click_on "Update Card"

    assert_text "Card was successfully updated"
    click_on "Back"
  end

  test "should destroy Card" do
    visit inventory_card_url(@inventory_card)
    click_on "Destroy this card", match: :first

    assert_text "Card was successfully destroyed"
  end
end
