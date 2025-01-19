require "test_helper"

class Inventory::CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @inventory_card = inventory_cards(:one)
  end

  test "should get index" do
    get inventory_cards_url
    assert_response :success
  end

  test "should get new" do
    get new_inventory_card_url
    assert_response :success
  end

  test "should create inventory_card" do
    assert_difference("Inventory::Card.count") do
      post inventory_cards_url, params: { inventory_card: {} }
    end

    assert_redirected_to inventory_card_url(Inventory::Card.last)
  end

  test "should show inventory_card" do
    get inventory_card_url(@inventory_card)
    assert_response :success
  end

  test "should get edit" do
    get edit_inventory_card_url(@inventory_card)
    assert_response :success
  end

  test "should update inventory_card" do
    patch inventory_card_url(@inventory_card), params: { inventory_card: {} }
    assert_redirected_to inventory_card_url(@inventory_card)
  end

  test "should destroy inventory_card" do
    assert_difference("Inventory::Card.count", -1) do
      delete inventory_card_url(@inventory_card)
    end

    assert_redirected_to inventory_cards_url
  end
end
