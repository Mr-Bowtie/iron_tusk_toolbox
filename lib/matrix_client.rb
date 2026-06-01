require "cgi"
require "securerandom"

module MatrixClient
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class MissingTokenError < ConfigurationError; end
  class RequestError < Error; end
  class NotAuthorizedError < RequestError; end

  def self.send_message(msg, http_client: MatrixHttpClient.new, transaction_id: SecureRandom.uuid)
    session = MatrixBotSession.current
    access_token = session.access_token_for_use!(http_client: http_client)

    begin
      send_text_message(msg, access_token:, http_client:, transaction_id:)
    rescue NotAuthorizedError
      raise unless session.refreshable?

      session.refresh!(http_client: http_client)
      send_text_message(msg, access_token: session.access_token, http_client:, transaction_id:)
    end
  end

  def self.send_text_message(msg, access_token:, http_client:, transaction_id:)
    http_client.put_json(
      message_path(transaction_id),
      body: {
        msgtype: "m.text",
        body: msg
      },
      access_token: access_token
    )
  end

  def self.message_path(transaction_id)
    room_id = ENV.fetch("MATRIX_ALERT_ROOM_ID", "").strip
    raise ConfigurationError, "MATRIX_ALERT_ROOM_ID is not configured" if room_id.blank?

    "/_matrix/client/v3/rooms/#{CGI.escape(room_id)}/send/m.room.message/#{CGI.escape(transaction_id)}"
  end
end
