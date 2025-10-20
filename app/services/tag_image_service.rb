class TagImageService
  class ImageDownloadError < StandardError; end

  def initialize(tag)
    @tag = tag
  end

  # Download image from any URL and attach to tag
  # @param url [String] The URL to download from
  # @param background [Boolean] Whether to process in background job
  def download_from_url(url, background: false)
    return unless url.present? && self.class.valid_image_url?(url)

      # if background
      #   TagImageDownloadJob.perform_later(@tag.id, url)
      # else
      perform_download(url)
    # end
  end

  # Download image from Discordrb attachment object
  # @param attachment [Discordrb::Attachment] Discord attachment object
  def download_from_discord_attachment(attachment)
    return unless attachment

    # Store the Discord CDN URL in original_image_url
    @tag.update_column(:original_image_url, attachment.url)

    # Queue background download to ActiveStorage
    TagImageDownloadJob.perform_later(@tag.id, attachment.url)
  end

  def perform_download(url)
    raise ImageDownloadError, "Tag not found" unless @tag

    # Use Discord::AttachmentDownloader for Discord URLs
    download_generic_image(url)

    # if discord_url?(url)
    #   download_discord_image(url)
    # else
    # end
  end

  private

  def download_discord_image(url)
    bot_token = Setting.discord_bot_token
    downloader = Discord::AttachmentDownloader.new(url, bot_token: bot_token)
    temp_file = downloader.download

    attach_file(temp_file, url)
  rescue Discord::AttachmentDownloader::DownloadError => e
    Rails.logger.error "Failed to download Discord image for tag #{@tag.id}: #{e.message}"
    raise ImageDownloadError, e.message
  ensure
    temp_file&.close
    temp_file&.unlink
  end

  def download_generic_image(url)
    require "open-uri"

    URI.open(url, "rb", read_timeout: 30) do |file|
      attach_file(file, url)
    end
  rescue OpenURI::HTTPError, SocketError, Timeout::Error => e
    Rails.logger.error "Failed to download image for tag #{@tag.id}: #{e.message}"
    raise ImageDownloadError, e.message
  end

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

  def extract_filename(url)
    uri = URI.parse(url)
    filename = File.basename(uri.path).split("?").first
    filename.presence || "image.jpg"
  rescue URI::InvalidURIError
    "image.jpg"
  end

  def discord_url?(url)
    uri = URI.parse(url)
    uri.host&.match?(/^(media|cdn)\.discordapp\.(net|com)$/i)
  rescue URI::InvalidURIError
    false
  end

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
end
