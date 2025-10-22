# Unified handler for tag image operations
# Handles all image-related logic for tags including:
# - Discord CDN URLs
# - ActiveStorage attachments
# - Content URLs
# - Image downloads
# - Display URLs
#
# Usage:
#   handler = Tags::ImageHandler.new(tag)
#   handler.display_url  # Get URL for display
#   handler.attach_from_source(url_or_file)  # Attach image from any source
#   handler.download_from_url(url)  # Download and attach from URL
module Tags
  class ImageHandler
    class ImageDownloadError < StandardError; end

    def initialize(tag)
      @tag = tag
    end

    # Get the display URL for a tag's image
    # Prioritizes Discord CDN URL, then ActiveStorage, then content URL
    # @return [String, nil] The image URL or nil if no image
    def display_url
      return @tag.discord_cdn_url if @tag.discord_cdn_url?
      return Rails.application.routes.url_helpers.rails_blob_url(@tag.image) if @tag.image.attached?
      return @tag.content if @tag.content_is_image_url?
      nil
    end

    # Attach an image to a tag from various sources
    # @param source [String, ActionDispatch::Http::UploadedFile] Image source
    # @return [void]
    def attach_from_source(source)
      return if source.blank?

      case source
      when ActionDispatch::Http::UploadedFile
        attach_from_upload(source)
      when String
        if discord_cdn_url?(source)
          attach_from_discord_cdn(source)
        elsif self.class.valid_image_url?(source)
          attach_from_url(source)
        end
      end
    end

    # Download image from any URL and attach to tag
    # @param url [String] The URL to download from
    def download_from_url(url)
      return unless url.present? && self.class.valid_image_url?(url)
      raise ImageDownloadError, "Tag not found" unless @tag

      download_image(url)
    end

    # Check if a URL is a Discord CDN URL
    # @param url [String] The URL to check
    # @return [Boolean] True if it's a Discord CDN URL
    def discord_cdn_url?(url)
      url.to_s.match?(%r{^https://cdn\.discordapp\.com/})
    end

    # Check if a URL is a valid image URL
    # @param url [String] The URL to check
    # @return [Boolean] True if it's a valid image URL
    def self.valid_image_url?(content)
      return false unless content.is_a?(String) && content.present?

      begin
        uri = URI.parse(content.strip)
        return false unless uri.scheme&.match?(/^https?$/i)

        # Check for image extensions
        has_image_extension = uri.path.match?(/\.(jpe?g|png|gif|webp|bmp|svg)$/i)

        # If it has an extension, it must be an image extension
        has_extension = uri.path.match?(/\.[a-z0-9]+$/i)
        return false if has_extension && !has_image_extension

        true
      rescue URI::InvalidURIError, ArgumentError
        false
      end
    end

    private

    # Attach image from Discord CDN URL
    # @param url [String] Discord CDN URL
    def attach_from_discord_cdn(url)
      @tag.discord_cdn_url = url
      @tag.original_image_url = url
      queue_download(url)
    end

    # Attach image from regular URL
    # @param url [String] Image URL
    def attach_from_url(url)
      @tag.original_image_url = url
      queue_download(url)
    end

    # Attach image from file upload
    # @param file [ActionDispatch::Http::UploadedFile] Uploaded file
    def attach_from_upload(file)
      @tag.image.attach(file)
    end

    # Queue image download job
    # @param url [String] Image URL to download
    def queue_download(url)
      TagImageDownloadJob.perform_later(@tag.id, url) if @tag.persisted?
    end

    # Download image from URL
    # @param url [String] The URL to download from
    def download_image(url)
      require "open-uri"

      URI.open(url, "rb", read_timeout: 30) do |file|
        attach_file(file, url)
      end
    rescue OpenURI::HTTPError, SocketError, Timeout::Error => e
      Rails.logger.error "Failed to download image for tag #{@tag.id}: #{e.message}"
      raise ImageDownloadError, e.message
    end

    # Attach downloaded file to tag
    # @param file [File] The downloaded file
    # @param url [String] Original URL
    def attach_file(file, url)
      filename = extract_filename(url)

      @tag.image.attach(
        io: file,
        filename: filename,
        content_type: Marcel::MimeType.for(file)
      )

      # Clear content field after successful attachment since image is now the source of truth
      @tag.update_column(:content, nil) if @tag.content.present? && @tag.content_is_image_url?

      Rails.logger.info "Successfully attached image to tag #{@tag.id} from #{url}"
    end

    # Extract filename from URL
    # @param url [String] The URL
    # @return [String] The filename
    def extract_filename(url)
      uri = URI.parse(url)
      filename = File.basename(uri.path).split("?").first
      filename.presence || "image.jpg"
    rescue URI::InvalidURIError
      "image.jpg"
    end
  end
end
