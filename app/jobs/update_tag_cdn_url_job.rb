# frozen_string_literal: true

# Job to cache Discord CDN URL after uploading an image to Discord
# This allows faster retrieval on subsequent /tag get commands
class UpdateTagCdnUrlJob < ApplicationJob
  queue_as :default

  def perform(tag_id, new_discord_cdn_url)
    tag = Tag.find(tag_id)

    # Always update if no cached URL or if the cached URL is expired
    if tag.discord_cdn_url.blank?
      tag.update!(discord_cdn_url: new_discord_cdn_url)
      Rails.logger.info "Cached Discord CDN URL for tag '#{tag.name}': #{new_discord_cdn_url}"
    else
      Rails.logger.info "Tag '#{tag.name}' already has valid Discord CDN URL, skipping update"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Tag #{tag_id} not found: #{e.message}"
  rescue => e
    Rails.logger.error "Failed to cache Discord CDN URL for tag #{tag_id}: #{e.message}"
    raise
  end
end
