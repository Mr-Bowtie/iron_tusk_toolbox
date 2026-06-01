require "test_helper"

class MatrixClientTest < ActiveSupport::TestCase
  class FakeHttpClient
    attr_reader :puts, :posts

    def initialize(put_responses:, post_responses: [])
      @put_responses = put_responses
      @post_responses = post_responses
      @puts = []
      @posts = []
    end

    def put_json(path, body:, access_token:)
      @puts << { path:, body:, access_token: }
      response = @put_responses.shift
      raise response if response.is_a?(Exception)

      response
    end

    def post_json(path, body:, access_token: nil)
      @posts << { path:, body:, access_token: }
      @post_responses.shift
    end
  end

  setup do
    MatrixBotSession.delete_all if defined?(MatrixBotSession)
    @session = MatrixBotSession.create!(
      access_token: "access-1",
      refresh_token: "refresh-1",
      expires_at: 1.hour.from_now
    )
  end

  test "send_message sends Matrix text with the persisted access token" do
    http_client = FakeHttpClient.new(put_responses: [ { "event_id" => "$event" } ])

    with_env("MATRIX_ALERT_ROOM_ID" => "!alerts:example.test") do
      MatrixClient.send_message("hello", http_client: http_client, transaction_id: "txn-1")
    end

    assert_equal 1, http_client.puts.length
    assert_equal "access-1", http_client.puts.first[:access_token]
    assert_equal "/_matrix/client/v3/rooms/%21alerts%3Aexample.test/send/m.room.message/txn-1", http_client.puts.first[:path]
    assert_equal({ msgtype: "m.text", body: "hello" }, http_client.puts.first[:body])
  end

  test "send_message refreshes and retries once when Matrix rejects an expired access token" do
    http_client = FakeHttpClient.new(
      put_responses: [
        MatrixClient::NotAuthorizedError.new("invalid token"),
        { "event_id" => "$event" }
      ],
      post_responses: [
        {
          "access_token" => "access-2",
          "refresh_token" => "refresh-2",
          "expires_in_ms" => 60_000
        }
      ]
    )

    with_env("MATRIX_ALERT_ROOM_ID" => "!alerts:example.test") do
      MatrixClient.send_message("hello", http_client: http_client, transaction_id: "txn-1")
    end

    assert_equal [ "access-1", "access-2" ], http_client.puts.map { |put| put[:access_token] }
    assert_equal "access-2", @session.reload.access_token
    assert_equal "refresh-2", @session.refresh_token
  end

  private

  def with_env(values)
    old_values = values.keys.to_h { |key| [ key, ENV[key] ] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    old_values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
