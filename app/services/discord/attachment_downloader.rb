require "net/http"
require "uri"
require "tempfile"

begin
  require "rest-client"
rescue LoadError
  # RestClient is optional
end

module Discord
  class AttachmentDownloader
    class DownloadError < StandardError; end

    DISCORD_CDN_HOST = "cdn.discordapp.com"
    DISCORD_API_BASE = "https://discord.com/api/v10"
    CHUNK_SIZE = 8192 # 8KB chunks for streaming

    def initialize(url, bot_token: nil)
      @original_url = url
      @url = url
      @bot_token = bot_token
      @uri = URI.parse(url)
    end

    # Extract Discord metadata from URL
    # Example: https://cdn.discordapp.com/attachments/845568081761796096/1413310512636235826/image.png
    def self.parse_url(url)
      uri = URI.parse(url)
      path_parts = uri.path.split('/')

      return {} unless path_parts[1] == 'attachments' && path_parts.length >= 5

      {
        discord_channel_id: path_parts[2],
        discord_message_id: path_parts[3],
        filename: path_parts[4]&.split('?')&.first
      }
    end

    # Check if a Discord CDN URL has expired based on its 'ex' parameter
    # @param url [String] Discord CDN URL
    # @return [Boolean] true if expired or expiring soon (within 1 hour), false otherwise
    def self.url_expired?(url)
      uri = URI.parse(url)
      params = URI.decode_www_form(uri.query || "").to_h

      # Extract expiration timestamp (ex parameter is Unix timestamp in hex)
      ex_hex = params["ex"]
      return false unless ex_hex

      # Convert hex to Unix timestamp
      expiration_time = Time.at(ex_hex.to_i(16))

      # Consider expired if within 1 hour of expiration (for safety)
      expiration_time <= Time.current + 1.hour
    rescue URI::InvalidURIError, ArgumentError
      # If we can't parse the URL or parameters, assume it might be expired
      true
    end

    def download
      validate_url!

      # If URL is expired and we have a bot token, fetch a fresh URL
      if url_expired? && @bot_token.present?
        @url = fetch_fresh_url
        @uri = URI.parse(@url)
      end

      temp_file = Tempfile.new(["discord_attachment_", file_extension], binmode: true)

      begin
        if use_rest_client?
          download_with_rest_client(temp_file)
        else
          response = fetch_with_retries
          stream_to_file(response, temp_file)
        end
        temp_file.rewind
        temp_file
      rescue => e
        temp_file.close
        temp_file.unlink
        raise DownloadError, "Failed to download attachment: #{e.message}"
      end
    end

    private

    def validate_url!
      unless @uri.host == DISCORD_CDN_HOST
        raise DownloadError, "Invalid Discord CDN URL: expected #{DISCORD_CDN_HOST}, got #{@uri.host}"
      end

      unless @uri.path.start_with?("/attachments/")
        raise DownloadError, "Invalid Discord attachment URL path"
      end
    end

    def url_expired?
      self.class.url_expired?(@original_url)
    end

    def fetch_fresh_url
      # Extract channel_id and message_id from the URL
      metadata = self.class.parse_url(@original_url)
      channel_id = metadata[:discord_channel_id]
      message_id = metadata[:discord_message_id]
      original_filename = metadata[:filename]

      unless channel_id && message_id
        raise DownloadError, "Cannot extract channel/message IDs from URL"
      end

      # Fetch message from Discord API
      api_url = "#{DISCORD_API_BASE}/channels/#{channel_id}/messages/#{message_id}"
      api_uri = URI.parse(api_url)

      response = Net::HTTP.start(api_uri.host, api_uri.port, use_ssl: true, read_timeout: 10) do |http|
        request = Net::HTTP::Get.new(api_uri)
        request["Authorization"] = "Bot #{@bot_token}"
        request["User-Agent"] = "DiscordBot (NadeshikorbArchiver, 1.0)"
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise DownloadError, "Failed to fetch message from Discord API: HTTP #{response.code}"
      end

      # Parse response and find the attachment
      message_data = JSON.parse(response.body)
      attachments = message_data["attachments"]

      unless attachments&.any?
        raise DownloadError, "No attachments found in Discord message"
      end

      # Find the matching attachment by filename
      attachment = if original_filename
        attachments.find { |a| a["filename"] == original_filename } || attachments.first
      else
        attachments.first
      end

      fresh_url = attachment["url"]
      unless fresh_url
        raise DownloadError, "No URL found in attachment data"
      end

      Rails.logger.info "Fetched fresh Discord URL for expired attachment (expires: #{attachment['proxy_url'] ? 'proxied' : 'direct'})"
      fresh_url
    rescue JSON::ParserError => e
      raise DownloadError, "Failed to parse Discord API response: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise DownloadError, "Timeout fetching fresh URL from Discord API: #{e.message}"
    end

    def fetch_with_retries(max_retries: 3)
      retries = 0
      redirect_count = 0

      begin
        response = make_request

        case response
        when Net::HTTPSuccess
          response
        when Net::HTTPRedirection
          # Follow redirects
          redirect_count += 1
          raise DownloadError, "Too many redirects" if redirect_count >= max_retries

          location = response["location"]
          @uri = URI.parse(location)
          fetch_with_retries(max_retries: max_retries - redirect_count)
        when Net::HTTPUnauthorized, Net::HTTPForbidden
          raise DownloadError, "Authentication failed. Discord bot token may be required or invalid."
        when Net::HTTPNotFound
          raise DownloadError, "Attachment not found. URL may be expired."
        else
          raise DownloadError, "HTTP #{response.code}: #{response.message}"
        end
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        retries += 1
        raise DownloadError, "Request timeout" if retries >= max_retries
        sleep(2**retries) # Exponential backoff
        retry
      end
    end

    def make_request
      Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https", read_timeout: 30) do |http|
        request = Net::HTTP::Get.new(@uri)
        request["User-Agent"] = "DiscordBot (NadeshikorbArchiver, 1.0)"

        # Add Discord bot authorization if token provided
        if @bot_token.present?
          request["Authorization"] = "Bot #{@bot_token}"
        end

        http.request(request)
      end
    end

    def stream_to_file(response, file)
      total_size = 0
      max_size = 100.megabytes # Safety limit

      response.read_body do |chunk|
        total_size += chunk.bytesize
        raise DownloadError, "File too large (> #{max_size} bytes)" if total_size > max_size
        file.write(chunk)
      end

      raise DownloadError, "Empty file downloaded" if total_size.zero?
    end

    def file_extension
      filename = @uri.path.split("/").last&.split("?")&.first
      return "" unless filename

      ext = File.extname(filename)
      ext.present? ? ext : ""
    end

    def use_rest_client?
      defined?(RestClient) && @bot_token.present?
    end

    def download_with_rest_client(file)
      headers = {
        "Authorization" => "Bot #{@bot_token}",
        "User-Agent" => "DiscordBot (NadeshikorbArchiver, 1.0)"
      }

      begin
        # RestClient.get returns the response body directly
        response = RestClient.get(@url, headers)
        file.write(response.body)

        raise DownloadError, "Empty file downloaded" if response.body.bytesize.zero?
        raise DownloadError, "File too large (> 100MB)" if response.body.bytesize > 100.megabytes
      rescue RestClient::Unauthorized, RestClient::Forbidden
        raise DownloadError, "Authentication failed. Discord bot token may be required or invalid."
      rescue RestClient::NotFound
        raise DownloadError, "Attachment not found. URL may be expired."
      rescue RestClient::Exception => e
        raise DownloadError, "RestClient error: #{e.message}"
      end
    end
  end
end
