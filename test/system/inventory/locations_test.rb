require "application_system_test_case"

class Inventory::LocationsTest < ApplicationSystemTestCase
  setup do
    @inventory_location = inventory_locations(:one)
  end

  test "visiting the index" do
    visit inventory_locations_url
    assert_selector "h1", text: "Locations"
  end

  test "should create location" do
    visit inventory_locations_url
    click_on "New location"

    click_on "Create Location"

    assert_text "Location was successfully created"
    click_on "Back"
  end

  test "should update Location" do
    visit inventory_location_url(@inventory_location)
    click_on "Edit this location", match: :first

    click_on "Update Location"

    assert_text "Location was successfully updated"
    click_on "Back"
  end

  test "should destroy Location" do
    visit inventory_location_url(@inventory_location)
    click_on "Destroy this location", match: :first

    assert_text "Location was successfully destroyed"
  end
end
