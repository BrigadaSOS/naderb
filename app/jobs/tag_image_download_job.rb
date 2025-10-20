class TagImageDownloadJob < ApplicationJob
  queue_as :default

  retry_on TagImageService::ImageDownloadError, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # @param tag_id [String] UUID of the tag
  # @param url [String] URL to download image from
  def perform(tag_id, url)
    tag = Tag.find_by(id: tag_id)

    unless tag
      Rails.logger.error "TagImageDownloadJob: Tag #{tag_id} not found"
      return
    end

    Rails.logger.info "TagImageDownloadJob: Downloading image for tag #{tag.name} (#{tag_id}) from #{url}"

    service = TagImageService.new(tag)
    service.perform_download(url)

    Rails.logger.info "TagImageDownloadJob: Successfully downloaded image for tag #{tag.name}"
  rescue TagImageService::ImageDownloadError => e
    Rails.logger.error "TagImageDownloadJob: Failed to download image for tag #{tag_id}: #{e.message}"
    raise
  rescue => e
    Rails.logger.error "TagImageDownloadJob: Unexpected error for tag #{tag_id}: #{e.class} - #{e.message}"
    raise
  end
end
