# == Schema Information
#
# Table name: matrix_bot_sessions
#
#  id            :bigint           not null, primary key
#  access_token  :text             not null
#  expires_at    :datetime
#  refresh_token :text
#  singleton     :boolean          default(TRUE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  device_id     :string           default("iron_tusk_alerts"), not null
#
# Indexes
#
#  index_matrix_bot_sessions_on_singleton  (singleton) UNIQUE
#
require "test_helper"

class MatrixBotSessionTest < ActiveSupport::TestCase
  class FakeHttpClient
    attr_reader :posts

    def initialize(response)
      @response = response
      @posts = []
    end

    def post_json(path, body:, access_token: nil)
      @posts << { path:, body:, access_token: }
      @response
    end
  end

  setup do
    MatrixBotSession.delete_all if defined?(MatrixBotSession)
  end

  test "refresh! stores rotated access and refresh tokens with a new expiry" do
    session = MatrixBotSession.create!(
      access_token: "old-access",
      refresh_token: "old-refresh",
      expires_at: 1.minute.ago,
      device_id: "iron_tusk_alerts"
    )
    http_client = FakeHttpClient.new(
      "access_token" => "new-access",
      "refresh_token" => "new-refresh",
      "expires_in_ms" => 3_600_000
    )

    travel_to Time.zone.local(2026, 5, 27, 9, 0, 0) do
      session.refresh!(http_client: http_client)
    end

    assert_equal [
      {
        path: "/_matrix/client/v3/refresh",
        body: { refresh_token: "old-refresh" },
        access_token: nil
      }
    ], http_client.posts
    assert_equal "new-access", session.reload.access_token
    assert_equal "new-refresh", session.refresh_token
    assert_equal Time.zone.local(2026, 5, 27, 10, 0, 0), session.expires_at
  end

  test "refresh! keeps existing refresh token when server does not rotate it" do
    session = MatrixBotSession.create!(
      access_token: "old-access",
      refresh_token: "old-refresh",
      expires_at: 1.minute.ago
    )
    http_client = FakeHttpClient.new(
      "access_token" => "new-access",
      "expires_in_ms" => 60_000
    )

    session.refresh!(http_client: http_client)

    assert_equal "new-access", session.reload.access_token
    assert_equal "old-refresh", session.refresh_token
  end

  test "access_token_for_use! refreshes tokens before returning an expired token" do
    session = MatrixBotSession.create!(
      access_token: "old-access",
      refresh_token: "old-refresh",
      expires_at: 1.second.ago
    )
    http_client = FakeHttpClient.new(
      "access_token" => "new-access",
      "refresh_token" => "new-refresh",
      "expires_in_ms" => 60_000
    )

    assert_equal "new-access", session.access_token_for_use!(http_client: http_client)
    assert_equal "new-refresh", session.reload.refresh_token
  end

  test "current bootstraps from the legacy env access token when the database has no session" do
    with_env(
      "MATRIX_ALERT_ACCESS_TOKEN" => "env-access",
      "MATRIX_ALERT_REFRESH_TOKEN" => "env-refresh",
      "MATRIX_ALERT_EXPIRES_IN_MS" => "60000"
    ) do
      travel_to Time.zone.local(2026, 5, 27, 9, 0, 0) do
        session = MatrixBotSession.current

        assert_equal "env-access", session.access_token
        assert_equal "env-refresh", session.refresh_token
        assert_equal Time.zone.local(2026, 5, 27, 9, 1, 0), session.expires_at
      end
    end
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
