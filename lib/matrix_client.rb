require "matrix_sdk"

module MatrixClient
  def self.send_message(msg)
    client = MatrixSdk::Client.new ENV.fetch("MATRIX_SERVER_URL", "").strip
    client.api.access_token = ENV.fetch("MATRIX_ALERT_ACCESS_TOKEN", "").strip
    # need to do this everytime to load the client cache with room info
    client.sync
    alert_room = client.find_room ENV["MATRIX_ALERT_ROOM_ID"]
    alert_room.send_text msg
  end
end
