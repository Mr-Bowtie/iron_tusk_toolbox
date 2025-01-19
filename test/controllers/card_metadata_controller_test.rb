require "test_helper"

class CardMetadataControllerTest < ActionDispatch::IntegrationTest
  setup do
    @card_metadatum = card_metadata(:one)
  end

  test "should get index" do
    get card_metadata_url
    assert_response :success
  end

  test "should get new" do
    get new_card_metadatum_url
    assert_response :success
  end

  test "should create card_metadatum" do
    assert_difference("CardMetadatum.count") do
      post card_metadata_url, params: { card_metadatum: { mana_cost: @card_metadatum.mana_cost, name: @card_metadatum.name, scryfall_id: @card_metadatum.scryfall_id, tcgplayer_id: @card_metadatum.tcgplayer_id } }
    end

    assert_redirected_to card_metadatum_url(CardMetadatum.last)
  end

  test "should show card_metadatum" do
    get card_metadatum_url(@card_metadatum)
    assert_response :success
  end

  test "should get edit" do
    get edit_card_metadatum_url(@card_metadatum)
    assert_response :success
  end

  test "should update card_metadatum" do
    patch card_metadatum_url(@card_metadatum), params: { card_metadatum: { mana_cost: @card_metadatum.mana_cost, name: @card_metadatum.name, scryfall_id: @card_metadatum.scryfall_id, tcgplayer_id: @card_metadatum.tcgplayer_id } }
    assert_redirected_to card_metadatum_url(@card_metadatum)
  end

  test "should destroy card_metadatum" do
    assert_difference("CardMetadatum.count", -1) do
      delete card_metadatum_url(@card_metadatum)
    end

    assert_redirected_to card_metadata_url
  end
end
