# Base service for Discord API interactions
# Provides shared HTTP logic, error handling, and response processing
# for both bot-level and user-level Discord API calls
module Discord
  module Api
  class BaseService
    include HTTParty
    base_uri "https://discord.com/api/v10"

    class RateLimitError < StandardError; end
    class ApiError < StandardError; end

    private

    # Perform a GET request with error handling
    # @param path [String] The API endpoint path
    # @param headers [Hash] Request headers
    # @param query [Hash] Query parameters
    # @return [Hash] Parsed response body
    def get(path, headers: {}, query: {})
      handle_response do
        self.class.get(path, headers: headers, query: query)
      end
    end

    # Perform a POST request with error handling
    # @param path [String] The API endpoint path
    # @param headers [Hash] Request headers
    # @param body [Hash] Request body (will be converted to JSON)
    # @return [Hash] Parsed response body
    def post(path, headers: {}, body: {})
      handle_response do
        self.class.post(path, headers: headers, body: body.to_json)
      end
    end

    # Perform a PUT request with error handling
    # @param path [String] The API endpoint path
    # @param headers [Hash] Request headers
    # @param body [Hash] Request body (will be converted to JSON)
    # @return [Hash] Parsed response body
    def put(path, headers: {}, body: {})
      handle_response do
        self.class.put(path, headers: headers, body: body.to_json)
      end
    end

    # Handle HTTP response and errors
    # @yield Block that performs the HTTP request
    # @return [Hash] Parsed response body
    # @raise [RateLimitError] If rate limited by Discord
    # @raise [ApiError] If request fails
    def handle_response
      response = yield

      case response.code
      when 200..299
        response.parsed_response
      when 429
        retry_after = response.parsed_response["retry_after"] || response.headers["retry-after"]
        raise RateLimitError, "Rate limited: retry after #{retry_after}s"
      else
        error_message = response.parsed_response["message"] rescue response.message
        raise ApiError, "Discord API error: #{response.code} - #{error_message}"
      end
    rescue JSON::ParserError => e
      raise ApiError, "Invalid JSON response: #{e.message}"
    end

    # Build headers for bot authentication
    # @param token [String] Bot token
    # @return [Hash] Headers with bot authorization
    def bot_headers(token)
      {
        "Authorization" => "Bot #{token}",
        "Content-Type" => "application/json",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      }
    end

    # Build headers for user OAuth authentication
    # @param access_token [String] User access token
    # @return [Hash] Headers with bearer authorization
    def user_headers(access_token)
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      }
    end

    # Log API errors
    # @param message [String] Error message
    # @param exception [Exception, nil] Optional exception
    def log_error(message, exception: nil)
      Rails.logger.error(message)
      Rails.logger.error(exception.full_message) if exception
    end
  end
end
end
