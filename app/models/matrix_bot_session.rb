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
class MatrixBotSession < ApplicationRecord
  REFRESH_WINDOW = 1.minute

  validates :access_token, presence: true
  validates :device_id, presence: true

  def self.current
    first || create_from_env!
  end

  def self.create_from_env!
    access_token = ENV.fetch("MATRIX_ALERT_ACCESS_TOKEN", "").strip
    raise MatrixClient::MissingTokenError, "MATRIX_ALERT_ACCESS_TOKEN is not configured" if access_token.blank?

    create!(
      access_token: access_token,
      refresh_token: ENV.fetch("MATRIX_ALERT_REFRESH_TOKEN", "").strip.presence,
      expires_at: expires_at_from_env,
      device_id: ENV.fetch("MATRIX_ALERT_DEVICE_ID", "iron_tusk_alerts").strip.presence || "iron_tusk_alerts"
    )
  end

  def self.expires_at_from_env
    expires_in_ms = ENV.fetch("MATRIX_ALERT_EXPIRES_IN_MS", "").strip
    return nil if expires_in_ms.blank?

    Time.current + (expires_in_ms.to_i / 1000.0).seconds
  end

  def access_token_for_use!(http_client: MatrixHttpClient.new)
    refresh!(http_client: http_client) if refreshable? && expires_soon?
    access_token
  end

  def refresh!(http_client: MatrixHttpClient.new)
    raise MatrixClient::MissingTokenError, "Matrix refresh token is not configured" if refresh_token.blank?

    response = http_client.post_json(
      "/_matrix/client/v3/refresh",
      body: { refresh_token: refresh_token }
    )

    update!(
      access_token: response.fetch("access_token"),
      refresh_token: response.fetch("refresh_token", refresh_token),
      expires_at: expires_at_from_response(response)
    )
  end

  def refreshable?
    refresh_token.present?
  end

  def expires_soon?
    expires_at.present? && expires_at <= REFRESH_WINDOW.from_now
  end

  private

  def expires_at_from_response(response)
    expires_in_ms = response["expires_in_ms"]
    return nil if expires_in_ms.blank?

    Time.current + (expires_in_ms.to_i / 1000.0).seconds
  end
end
