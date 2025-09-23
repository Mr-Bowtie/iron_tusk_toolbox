require "test_helper"

class PullBatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pull_batch = pull_batches(:one)
  end

  test "should get index" do
    get pull_batches_url
    assert_response :success
  end

  test "should get new" do
    get new_pull_batch_url
    assert_response :success
  end

  test "should create pull_batch" do
    assert_difference("PullBatch.count") do
      post pull_batches_url, params: { pull_batch: {} }
    end

    assert_redirected_to pull_batch_url(PullBatch.last)
  end

  test "should show pull_batch" do
    get pull_batch_url(@pull_batch)
    assert_response :success
  end

  test "should get edit" do
    get edit_pull_batch_url(@pull_batch)
    assert_response :success
  end

  test "should update pull_batch" do
    patch pull_batch_url(@pull_batch), params: { pull_batch: {} }
    assert_redirected_to pull_batch_url(@pull_batch)
  end

  test "should destroy pull_batch" do
    assert_difference("PullBatch.count", -1) do
      delete pull_batch_url(@pull_batch)
    end

    assert_redirected_to pull_batches_url
  end
end
