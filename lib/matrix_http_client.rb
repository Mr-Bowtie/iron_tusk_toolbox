require "json"
require "net/http"
require "uri"

class MatrixHttpClient
  def initialize(server_url: ENV.fetch("MATRIX_SERVER_URL", "").strip)
    raise MatrixClient::ConfigurationError, "MATRIX_SERVER_URL is not configured" if server_url.blank?

    @server_uri = URI(server_url)
  end

  def post_json(path, body:, access_token: nil)
    request_json(Net::HTTP::Post, path, body:, access_token:)
  end

  def put_json(path, body:, access_token: nil)
    request_json(Net::HTTP::Put, path, body:, access_token:)
  end

  private

  def request_json(request_class, path, body:, access_token:)
    uri = @server_uri + path
    request = request_class.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}" if access_token.present?
    request.body = JSON.generate(body)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    parsed_body = parse_body(response.body)

    case response.code.to_i
    when 200..299
      parsed_body
    when 401, 403
      raise MatrixClient::NotAuthorizedError, parsed_body.fetch("error", response.message)
    else
      raise MatrixClient::RequestError, "Matrix request failed with #{response.code}: #{parsed_body.fetch("error", response.body)}"
    end
  end

  def parse_body(body)
    return {} if body.blank?

    JSON.parse(body)
  rescue JSON::ParserError
    { "error" => body.to_s }
  end
end
