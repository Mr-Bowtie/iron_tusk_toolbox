require "application_system_test_case"

class PullBatchesTest < ApplicationSystemTestCase
  setup do
    @pull_batch = pull_batches(:one)
  end

  test "visiting the index" do
    visit pull_batches_url
    assert_selector "h1", text: "Pull batches"
  end

  test "should create pull batch" do
    visit pull_batches_url
    click_on "New pull batch"

    click_on "Create Pull batch"

    assert_text "Pull batch was successfully created"
    click_on "Back"
  end

  test "should update Pull batch" do
    visit pull_batch_url(@pull_batch)
    click_on "Edit this pull batch", match: :first

    click_on "Update Pull batch"

    assert_text "Pull batch was successfully updated"
    click_on "Back"
  end

  test "should destroy Pull batch" do
    visit pull_batch_url(@pull_batch)
    click_on "Destroy this pull batch", match: :first

    assert_text "Pull batch was successfully destroyed"
  end
end
